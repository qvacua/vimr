/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Scorer {

  static func score(_ target: String, pattern: String) -> Int {
    let fuzzy = Matcher.fuzzyIgnoringCase(target, pattern: pattern)
    let upper = Matcher.numberOfUppercaseMatches(target, pattern: pattern)
    let exactMatch = Matcher.exactMatchIgnoringCase(target, pattern: pattern)
    let wf = Matcher.wagnerFisherDistance(target, pattern: pattern)

    let exactScore: Int
    switch exactMatch {
    case .none:
      exactScore = 0
    case .exact:
      return 1000
    case .prefix, .contains, .suffix:
      exactScore = 5
    }

    return exactScore
           + 10 * fuzzy
           + 5 * upper
           - wf
  }
}
