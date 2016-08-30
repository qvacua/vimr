/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class ScoredFileItem: Comparable {
  let score: Float
  let url: NSURL

  init(score: Float, url: NSURL) {
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
