/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Scorer {
  
  static func score(target: String, pattern: String) -> Int {
    let wf = Matcher.wagnerFisherDistance(target, pattern: pattern)
    let fuzzy = Matcher.fuzzyIgnoringCase(target, pattern: pattern)
    let upper = Matcher.numberOfUppercaseMatches(target, pattern: pattern)
    let exactMatch = Matcher.exactMatchIgnoringCase(target, pattern: pattern)

    let exactScore: Int
    switch exactMatch {
    case .none:
      exactScore = 0
    case .exact:
      return 100
    case .prefix, .contains, .suffix:
      exactScore = 5
    }

    let wfScore = 0 - (wf / 10)

    return exactScore
      + wfScore
      + fuzzy.matches
      + 2 * upper
  }
}
