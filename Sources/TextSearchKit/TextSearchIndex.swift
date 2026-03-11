//
//  Copyright © 2020 Apparata AB. All rights reserved.
//

import Foundation
import CoreServices

/// For normal (non-similarity-based) queries, Search Kit discerns the type of
/// query—Boolean, prefix, phrase, and so on—from the syntax of the query
/// itself. Moreover, Search Kit supports multiple query types within a single
/// search. For example, the following query includes Boolean, prefix, and
/// suffix searching:
///
/// ```
/// appl* OR *ing
/// ```
///
/// This query will return documents containing words that begin with "appl"
/// as well as documents that contain words that end with "ing".
///
/// For similarity searches, specified with the kSKSearchOptionFindSimilar
/// flag in the inSearchOptions parameter, SKSearchCreate ignores all query
/// operators.
///
/// The query operators that SKSearchCreate recognizes for non-similarity
/// searching are:
///
/// - `AND`- Boolean AND
/// - `&` - Boolean AND
/// - `<space>` - Boolean AND by default when no other operator is present,
///               or Boolean OR if specified by kSKSearchOptionSpaceMeansOR.
/// - `OR` - Boolean inclusive OR
/// - `|` - Boolean inclusive OR
/// - `NOT` - Boolean NOT (see Special Considerations)
/// - `!` - Boolean NOT (see Special Considerations)
/// - `*` - Wildcard for prefix or suffix; surround term with wildcard
///         characters for substring search. Ignored in phrase searching.
/// - `(` - Begin logical grouping
/// - `)` - End logical grouping
/// - `"` - Delimiter for phrase searching
///
/// NOTE: The operators AND, OR, and NOT are case sensitive.
///
public class TextSearchIndex {

    private let indexActor: IndexActor

    public class Index: @unchecked Sendable {

        internal let index: SKIndex

        fileprivate init(stopWords: [String] = defaultStopWords) {

            let properties: [NSObject: AnyObject] = [
                //kSKStartTermChars: "" as NSString, // additional starting-characters for terms
                kSKTermChars: "_" as NSString, // additional characters within terms
                //kSKEndTermChars: "" as NSString,
                kSKMinTermLength: 3 as NSNumber,
                kSKStopWords: NSSet(array: stopWords as [NSString]),
                kSKProximityIndexing: kCFBooleanTrue
            ]
            index = SKIndexCreateWithMutableData(
                NSMutableData(), nil, kSKIndexInverted, properties as CFDictionary)
                .takeRetainedValue()
        }

        fileprivate init(creatingAt url: URL, named: String? = nil, stopWords: [String] = defaultStopWords) throws {
            let properties: [NSObject: AnyObject] = [
                kSKTermChars: "_" as NSString,
                kSKMinTermLength: 3 as NSNumber,
                kSKStopWords: NSSet(array: stopWords as [NSString]),
                kSKProximityIndexing: kCFBooleanTrue
            ]
            guard let skIndex = SKIndexCreateWithURL(
                url as NSURL,
                named as NSString?,
                kSKIndexInverted,
                properties as CFDictionary
            )?.takeRetainedValue() else {
                throw TextSearchIndexerError.failedToCreateIndex(url)
            }
            index = skIndex
        }

        fileprivate init(openingAt url: URL, named: String? = nil, writable: Bool) throws {
            guard let skIndex = SKIndexOpenWithURL(
                url as NSURL,
                named as NSString?,
                writable
            )?.takeRetainedValue() else {
                throw TextSearchIndexerError.failedToOpenIndex(url)
            }
            index = skIndex
        }

        fileprivate func flush() {
            SKIndexFlush(index)
        }

        fileprivate func close() {
            SKIndexClose(index)
        }

        public func documentCount() -> Int {
            SKIndexGetDocumentCount(index)
        }

        public func documentState(for url: URL) -> TextSearchDocumentState {
            let unmanagedDocument = SKDocumentCreateWithURL(url as NSURL)
            guard let document = unmanagedDocument?.takeRetainedValue() else {
                return .notIndexed
            }
            return TextSearchDocumentState(SKIndexGetDocumentState(index, document))
        }

        @discardableResult
        public func compact() -> Bool {
            SKIndexCompact(index)
        }
    }

    private actor IndexActor {
        let index: Index

        init(index: Index) {
            self.index = index
        }

        func perform(_ actions: @Sendable (Index) throws -> Void) rethrows {
            try actions(index)
            index.flush()
        }

        func close() {
            index.close()
        }

        func documentCount() -> Int {
            index.documentCount()
        }

        func documentState(for url: URL) -> TextSearchDocumentState {
            index.documentState(for: url)
        }

        func compact() -> Bool {
            index.compact()
        }

        func search(for string: String,
                     options: TextSearchOption,
                     limit: Int,
                     time: TimeInterval) -> [TextSearchMatch] {
            SKIndexFlush(index.index)
            let searchOptions = SKSearchOptions(options.rawValue)
            let search = SKSearchCreate(index.index, string as NSString, searchOptions).takeRetainedValue()

            var result: [TextSearchMatch] = []
            var hasMoreResults = true
            while hasMoreResults {
                var documentIDs: [SKDocumentID] = Array(repeating: 0, count: limit)
                var scores: [Float] = Array(repeating: 0, count: limit)
                var foundCount = 0

                hasMoreResults = SKSearchFindMatches(search, limit, &documentIDs, &scores, time, &foundCount)

                guard foundCount > 0 else {
                    break
                }

                var urls: [Unmanaged<CFURL>?] = Array(repeating: nil, count: limit)
                SKIndexCopyDocumentURLsForDocumentIDs(index.index, foundCount, &documentIDs, &urls)

                let urlsAndScores: [(Unmanaged<CFURL>?, Float)] = Array(zip(urls[0..<foundCount], scores))
                let matches: [TextSearchMatch] = urlsAndScores.compactMap { cfURL, score in
                    guard let nsURL = cfURL?.takeRetainedValue() as NSURL? else {
                        return nil
                    }
                    return TextSearchMatch(url: nsURL as URL, score: score)
                }

                result.append(contentsOf: matches)
            }

            return result
        }
    }

    public init() {
        let index = Index()
        indexActor = IndexActor(index: index)
    }

    public init(creatingAt url: URL, named: String? = nil, stopWords: [String] = defaultStopWords) throws {
        let index = try Index(creatingAt: url, named: named, stopWords: stopWords)
        indexActor = IndexActor(index: index)
    }

    public init(openingAt url: URL, named: String? = nil, writable: Bool = true) throws {
        let index = try Index(openingAt: url, named: named, writable: writable)
        indexActor = IndexActor(index: index)
    }

    public func index(_ actions: @Sendable (Index) throws -> Void) async rethrows {
        try await indexActor.perform(actions)
    }

    public func addDocument(fileURL url: URL, mimeTypeHint: String = "text/plain") async throws {
        try await index { index in
            try index.addDocument(fileURL: url, mimeTypeHint: mimeTypeHint)
        }
    }

    public func addDocument(identifyingURL url: URL, content: String) async throws {
        try await index { index in
            try index.addDocument(identifyingURL: url, content: content)
        }
    }

    public func removeDocument(url: URL) async throws {
        try await index { index in
            try index.removeDocument(url: url)
        }
    }

    public func search(for string: String,
                       options: TextSearchOption = .defaultOptions,
                       limit: Int,
                       time: TimeInterval) async -> [TextSearchMatch] {
        await indexActor.search(for: string, options: options, limit: limit, time: time)
    }

    public func close() async {
        await indexActor.close()
    }

    public func documentCount() async -> Int {
        await indexActor.documentCount()
    }

    public func documentState(for url: URL) async -> TextSearchDocumentState {
        await indexActor.documentState(for: url)
    }

    @discardableResult
    public func compact() async -> Bool {
        await indexActor.compact()
    }
}

extension TextSearchIndex.Index: TextSearchIndexer {

    public func addDocument(fileURL url: URL, mimeTypeHint: String = "text/plain") throws {
        assert(url.isFileURL)
        let unmanagedDocument = SKDocumentCreateWithURL(url as NSURL)
        guard let document = unmanagedDocument?.takeRetainedValue() else {
            throw TextSearchIndexerError.failedToIndex(url)
        }
        let success = SKIndexAddDocument(index, document, mimeTypeHint as NSString, true)
        guard success else {
            throw TextSearchIndexerError.failedToIndex(url)
        }
    }

    public func addDocument(identifyingURL url: URL, content: String) throws {
        let unmanagedDocument = SKDocumentCreateWithURL(url as NSURL)
        guard let document = unmanagedDocument?.takeRetainedValue() else {
            throw TextSearchIndexerError.failedToIndex(url)
        }
        let success = SKIndexAddDocumentWithText(index, document, content as NSString, true)
        guard success else {
            throw TextSearchIndexerError.failedToIndex(url)
        }
    }

    public func removeDocument(url: URL) throws {
        let unmanagedDocument = SKDocumentCreateWithURL(url as NSURL)
        guard let document = unmanagedDocument?.takeRetainedValue() else {
            throw TextSearchIndexerError.failedToRemove(url)
        }
        let success = SKIndexRemoveDocument(index, document)
        guard success else {
            throw TextSearchIndexerError.failedToRemove(url)
        }
    }
}
