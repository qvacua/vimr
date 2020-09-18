/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Nimble
import XCTest

@testable import Commons

class FifoCacheTest: XCTestCase {
  var fifo: FifoCache<Int, Int>!

  override func setUp() {
    super.setUp()
    self.fifo = FifoCache(count: 10, queueQos: .default)
  }

  func testSimpleGet() {
    for i in 0...5 { self.fifo.set(i, forKey: i) }

    for i in 0...5 { expect(self.fifo.valueForKey(i)).to(equal(i)) }
    for i in 6..<10 { expect(self.fifo.valueForKey(i)).to(beNil()) }
  }

  func testGet() {
    for i in 0..<(10 * 3) { self.fifo.set(i, forKey: i) }
    for i in 20..<30 { expect(self.fifo.valueForKey(i)).to(equal(i)) }
    expect(self.fifo.valueForKey(19)).to(beNil())
    expect(self.fifo.valueForKey(30)).to(beNil())
  }
}
