//
//  Copyright © 2020 Apparata AB. All rights reserved.
//

import Foundation

public protocol TextSearchIndexer {
    func addDocument(fileURL: URL, mimeTypeHint: String) throws
    func addDocument(identifyingURL: URL, content: String) throws
}
