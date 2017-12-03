/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class ScoredFileItem: Comparable {
  let score: Int
  let url: URL

  init(score: Int, url: URL) {
    self.score = score
    self.url = url
  }
}

func == (left: ScoredFileItem, right: ScoredFileItem) -> Bool {
  return left.score == right.score
}

func <(left: ScoredFileItem, right: ScoredFileItem) -> Bool {
  return left.score < right.score
}
