/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble
import RxSwift
import RxTest
@testable import VimR

class RxSwiftCommonsTest: XCTestCase {

  func testMapOmittingNil() {
    let scheduler = TestScheduler(initialClock: 0)

    let xs = scheduler.createHotObservable(
      [
        next(150, 1),
        next(210, 2),
        next(220, 3),
        next(230, 4),
        next(240, 5),
        next(260, 6),
        completed(300)
      ]
    )

    let res = scheduler.start { xs.mapOmittingNil { $0 % 2 == 0 ? $0 : nil } }

    let correctMessages = [
      next(210, 2),
      next(230, 4),
      next(260, 6),
      completed(300)
    ]

    XCTAssertEqual(res.events, correctMessages)
  }
}
