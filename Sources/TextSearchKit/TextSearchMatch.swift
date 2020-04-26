//
//  Copyright © 2020 Apparata AB. All rights reserved.
//

import Foundation

public struct TextSearchMatch {
    public let url: URL
    public let score: Float
    
    public init(url: URL, score: Float) {
        self.url = url
        self.score = score
    }
}

extension TextSearchMatch: Identifiable, Hashable {
    public var id: String {
        return url.absoluteString
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url
    }
}
