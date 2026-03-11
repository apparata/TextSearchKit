//
//  Copyright © 2020 Apparata AB. All rights reserved.
//

import Foundation

public enum TextSearchIndexerError: Error, Sendable {
    case failedToIndex(URL)
}
