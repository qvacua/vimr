/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class ScoredFileItem: Comparable {
  let score: Int
  unowned let url: NSURL

  init(score: Int, url: NSURL) {
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
