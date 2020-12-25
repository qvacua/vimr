/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Nimble
import RxSwift
import RxTest
import XCTest

class RxSwiftCommonsTest: XCTestCase {
  func testMapOmittingNil() {
    let scheduler = TestScheduler(initialClock: 0)

    let xs = scheduler.createHotObservable(
      [
        Recorded.next(150, 1),
        Recorded.next(210, 2),
        Recorded.next(220, 3),
        Recorded.next(230, 4),
        Recorded.next(240, 5),
        Recorded.next(260, 6),
        Recorded.completed(300),
      ]
    )

    let res = scheduler.start { xs.compactMap { $0 % 2 == 0 ? $0 : nil } }

    let correctMessages = [
      Recorded.next(210, 2),
      Recorded.next(230, 4),
      Recorded.next(260, 6),
      Recorded.completed(300),
    ]

    expect(res.events).to(equal(correctMessages))
  }
}
