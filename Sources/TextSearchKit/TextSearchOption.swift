//
//  Copyright © 2020 Apparata AB. All rights reserved.
//

import Foundation
import CoreServices

public struct TextSearchOption: OptionSet {

    /// Saves search time by suppressing the computation of relevance scores.
    ///
    /// - Relevance scores will be computed.
    /// - Spaces in a query are interpreted as Boolean AND operators.
    /// - Do not use similarity searching.
    public static let defaultOptions = TextSearchOption(rawValue: kSKSearchOptionDefault)
    
    /// Saves search time by suppressing the computation of relevance scores.
    public static let noRelevanceScores = TextSearchOption(rawValue: kSKSearchOptionNoRelevanceScores)
    
    /// Spaces in search stringare interpreted as OR instead of AND.
    public static let spaceMeansOr = TextSearchOption(rawValue: kSKSearchOptionSpaceMeansOR)
    
    /// Also return matches that are similar to search string.
    /// All query operators are ignored when this options is set.
    public static let findSimilar = TextSearchOption(rawValue: kSKSearchOptionFindSimilar)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
