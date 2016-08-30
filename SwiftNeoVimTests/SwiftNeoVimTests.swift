/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble
@testable import SwiftNeoVim

class GridTest: XCTestCase {

  func testStub() {
    let g = Grid()
    expect(g.foreground).to(equal(qDefaultForeground))
  }
}
