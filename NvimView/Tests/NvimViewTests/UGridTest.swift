/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Nimble
import XCTest

@testable import NvimView

class UGridTest: XCTestCase {
  private let ugrid = UGrid()

  func testFlatCharIndex() {
    self.ugrid.resize(Size(width: 10, height: 3))

    self.ugrid.update(
      row: 0,
      startCol: 0, endCol: 10,
      clearCol: 0, clearAttr: 0,
      chunk: ["0", "하", "", "3", "4", "태", "", "7", "8", "9"],
      attrIds: Array(repeating: 0, count: 10)
    )
    self.ugrid.recomputeFlatIndices(rowStart: 0)

    expect(self.ugrid.cells.reduce(into: []) { result, row in
      result.append(contentsOf: row.reduce(into: []) { rowResult, cell in
        rowResult.append(cell.flatCharIndex)
      })
    }).to(equal(
      [
        0, 1, 1, 2, 3, 4, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
        18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
      ]
    ))

    self.ugrid.update(
      row: 1,
      startCol: 5, endCol: 7,
      clearCol: 0, clearAttr: 0,
      chunk: ["하", ""],
      attrIds: Array(repeating: 0, count: 2)
    )
    self.ugrid.recomputeFlatIndices(rowStart: 0)

    expect(self.ugrid.cells.reduce(into: []) { result, row in
      result.append(contentsOf: row.reduce(into: []) { rowResult, cell in
        rowResult.append(cell.flatCharIndex)
      })
    }).to(equal(
      [
        0, 1, 1, 2, 3, 4, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
      ]
    ))

    self.ugrid.update(
      row: 2,
      startCol: 8, endCol: 10,
      clearCol: 0, clearAttr: 0,
      chunk: ["하", ""],
      attrIds: Array(repeating: 0, count: 2)
    )
    self.ugrid.recomputeFlatIndices(rowStart: 0)

    expect(self.ugrid.cells.reduce(into: []) { result, row in
      result.append(contentsOf: row.reduce(into: []) { rowResult, cell in
        rowResult.append(cell.flatCharIndex)
      })
    }).to(equal(
      [
        0, 1, 1, 2, 3, 4, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 23, 24, 25, 25,
      ]
    ))
  }

  func testLeftBoundaryOfWord() {
    self.ugrid.resize(Size(width: 10, height: 2))
    self.ugrid.update(
      row: 0,
      startCol: 0,
      endCol: 10,
      clearCol: 10,
      clearAttr: 0,
      chunk: " 12 45678 ".compactMap { String($0) },
      attrIds: [Int](repeating: 0, count: 10)
    )

    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 9)))
      .to(equal(9))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 8)))
      .to(equal(4))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 4)))
      .to(equal(4))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 3)))
      .to(equal(3))
    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 0, column: 0)))
      .to(equal(0))

    self.ugrid.update(
      row: 1,
      startCol: 0,
      endCol: 10,
      clearCol: 10,
      clearAttr: 0,
      chunk: "0123456789".compactMap { String($0) },
      attrIds: [Int](repeating: 0, count: 10)
    )

    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 1, column: 0)))
      .to(equal(0))
  }

  func testRightBoundaryOfWord() {
    self.ugrid.resize(Size(width: 10, height: 2))
    self.ugrid.update(
      row: 0,
      startCol: 0,
      endCol: 10,
      clearCol: 10,
      clearAttr: 0,
      chunk: " 12345 78 ".compactMap { String($0) },
      attrIds: [Int](repeating: 0, count: 10)
    )

    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 9)))
      .to(equal(9))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 8)))
      .to(equal(8))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 7)))
      .to(equal(8))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 1)))
      .to(equal(5))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 0, column: 0)))
      .to(equal(0))

    self.ugrid.update(
      row: 1,
      startCol: 0,
      endCol: 10,
      clearCol: 10,
      clearAttr: 0,
      chunk: "0123456789".compactMap { String($0) },
      attrIds: [Int](repeating: 0, count: 10)
    )
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 1, column: 9)))
      .to(equal(9))
  }
}
