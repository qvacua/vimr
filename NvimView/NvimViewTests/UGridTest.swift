/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import XCTest
import Nimble

@testable import NvimView

class UGridTest: XCTestCase {

  private let ugrid = UGrid()

  override func setUp() {
    self.ugrid.resize(Size(width: 10, height: 2))
  }

  func testLeftBoundaryOfWord() {
    self.ugrid.update(row: 0,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: " 12 45678 ".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))

    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 9))).to(equal(9))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 8))).to(equal(4))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 4))).to(equal(4))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 3))).to(equal(3))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 0))).to(equal(0))

    self.ugrid.update(row: 1,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: "0123456789".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))

    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 1, column: 0))).to(equal(0))
  }

  func testRightBoundaryOfWord() {
    self.ugrid.update(row: 0,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: " 12345 78 ".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))

    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 9))).to(equal(9))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 8))).to(equal(8))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 7))).to(equal(8))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 1))).to(equal(5))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 0))).to(equal(0))

    self.ugrid.update(row: 1,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: "0123456789".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 1, column: 9))).to(equal(9))
  }
}
