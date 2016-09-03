/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Scorer {
  
  static func score(target: String, pattern: String) -> Float {
    let wf = Matcher.wagnerFisherDistance(target, pattern: pattern)
//    let fuzzy = Matcher.fuzzyIgnoringCase(target, pattern: pattern)
    let upper = Matcher.numberOfUppercaseMatches(target, pattern: pattern)
    let exactMatch = Matcher.exactMatchIgnoringCase(target, pattern: pattern)

    let exactScore: Float
    switch exactMatch {
    case .none:
      exactScore = 0
    case .exact:
      return 100
    case .prefix, .contains, .suffix:
      exactScore = 5
    }
    
    return (wf == 0 ? 0 : 5.0 / Float(wf))
//      + Float(fuzzy.matches)
      + Float(upper)
      + exactScore
  }
}
