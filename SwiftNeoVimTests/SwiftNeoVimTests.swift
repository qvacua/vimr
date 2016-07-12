/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Quick
import Nimble
@testable import SwiftNeoVim

class GridSpec: QuickSpec {

  override func spec() {
    describe("something") {
      it("does things") {
        let g = Grid()
        expect(g.foreground).to(equal(qDefaultForeground))
      }
    }
  }
}
