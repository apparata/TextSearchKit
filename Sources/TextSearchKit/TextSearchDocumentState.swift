//
//  Copyright © 2020 Apparata AB. All rights reserved.
//

import CoreServices

/// The indexing state of a document in a search index.
public enum TextSearchDocumentState: Sendable {
    case notIndexed
    case indexed
    case addPending
    case deletePending

    init(_ state: SKDocumentIndexState) {
        switch state {
        case kSKDocumentStateIndexed: self = .indexed
        case kSKDocumentStateAddPending: self = .addPending
        case kSKDocumentStateDeletePending: self = .deletePending
        default: self = .notIndexed
        }
    }
}
