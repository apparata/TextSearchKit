# TextSearchKit

A Swift package that wraps Apple's [Search Kit](https://developer.apple.com/documentation/coreservices/search_kit) framework, providing a modern API for full-text search indexing and retrieval on macOS.

## Requirements

- macOS 14+
- Swift 6.2+

## Usage

### Indexing Documents

```swift
import TextSearchKit

let searchIndex = TextSearchIndex()

// Index a file
try await searchIndex.addDocument(fileURL: documentURL, mimeTypeHint: "text/plain")

// Index arbitrary content
try await searchIndex.addDocument(identifyingURL: someURL, content: "The content to index.")
```

For bulk indexing, use the closure-based `index` method to batch operations with a single flush:

```swift
try await searchIndex.index { index in
    try index.addDocument(identifyingURL: url1, content: "First document")
    try index.addDocument(identifyingURL: url2, content: "Second document")
    try index.addDocument(identifyingURL: url3, content: "Third document")
}
```

### Searching

```swift
let matches = await searchIndex.search(for: "query", limit: 50, time: 1.0)
for match in matches {
    print("\(match.url): \(match.score)")
}
```

### Query Syntax

The full Search Kit query syntax is supported:

- **Boolean operators:** `AND` (`&`), `OR` (`|`), `NOT` (`!`)
- **Wildcards:** `*` for prefix, suffix, or substring matching (e.g. `appl*`, `*ing`)
- **Phrases:** `"exact phrase"`
- **Grouping:** Parentheses for logical grouping

### Persistent Index

Create a file-backed index that persists across app launches:

```swift
// Create a new index on disk
let searchIndex = try TextSearchIndex(creatingAt: indexFileURL)

// Open an existing index
let searchIndex = try TextSearchIndex(openingAt: indexFileURL)

// Open read-only
let searchIndex = try TextSearchIndex(openingAt: indexFileURL, writable: false)

// Close when done
await searchIndex.close()
```

### Document State & Count

```swift
let count = await searchIndex.documentCount()

let state = await searchIndex.documentState(for: documentURL)
// .notIndexed, .indexed, .addPending, .deletePending
```

### Compaction

Reclaim disk space and optimize the index after removing documents:

```swift
await searchIndex.compact()
```

### Search Options

```swift
// Default search with relevance scoring
await searchIndex.search(for: "query", options: .defaultOptions, limit: 50, time: 1.0)

// Treat spaces as OR instead of AND
await searchIndex.search(for: "swift framework", options: .spaceMeansOr, limit: 50, time: 1.0)

// Find similar documents
await searchIndex.search(for: "sample text", options: .findSimilar, limit: 20, time: 1.0)
```

## License

TextSearchKit is released under the [BSD Zero Clause License](LICENSE) (0BSD).
