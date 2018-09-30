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

  func testMarkPosition() {
    self.ugrid.resize(Size(width: 20, height: 10))
    self.ugrid.update(
      row: 9,
      startCol: 0,
      endCol: 9,
      clearCol: 0,
      clearAttr: 0,
      chunk: Array("0123456789".compactMap { String($0) }),
      attrIds: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    )
    self.ugrid.markCell(at: Position(row: 9, column: 4))
    expect(self.ugrid.cells[9][4].attrId).to(equal(-4))

    self.ugrid.update(
      row: 7,
      startCol: 0,
      endCol: 9,
      clearCol: 0,
      clearAttr: 0,
      chunk: Array("23456789".compactMap { String($0) }) + ["하", ""],
      attrIds: [0, 1, 2, 3, 4, 5, 6, 7, 8, 8]
    )
    self.ugrid.markCell(at: Position(row: 7, column: 8))
    expect(self.ugrid.cells[7][8].attrId)
      .to(equal(-8))
    expect(self.ugrid.cells[7][9].attrId)
      .to(equal(-8))

    self.ugrid.update(
      row: 8,
      startCol: 0,
      endCol: 9,
      clearCol: 0,
      clearAttr: 0,
      chunk: ["하", ""] + Array("23456789".compactMap { String($0) }),
      attrIds: [0, 0, 2, 3, 4, 5, 6, 7, 8, 9]
    )
    self.ugrid.markCell(at: Position(row: 8, column: 0))
    expect(self.ugrid.cells[8][0].attrId)
      .to(equal(CellAttributesCollection.reversedDefaultAttributesId))
    expect(self.ugrid.cells[8][1].attrId)
      .to(equal(CellAttributesCollection.reversedDefaultAttributesId))
  }

  func testFlattenedIndex() {
    self.ugrid.resize(Size(width: 20, height: 10))
    expect(
      self.ugrid.flattenedCellIndex(forPosition: Position(row: 0, column: 0))
    ).to(equal(0))
    expect(
      self.ugrid.flattenedCellIndex(forPosition: Position(row: 0, column: 5))
    ).to(equal(5))
    expect(
      self.ugrid.flattenedCellIndex(forPosition: Position(row: 1, column: 0))
    ).to(equal(20))
    expect(
      self.ugrid.flattenedCellIndex(forPosition: Position(row: 1, column: 5))
    ).to(equal(25))
    expect(
      self.ugrid.flattenedCellIndex(forPosition: Position(row: 9, column: 0))
    ).to(equal(180))
    expect(
      self.ugrid.flattenedCellIndex(forPosition: Position(row: 9, column: 19))
    ).to(equal(199))
  }

  func testPositionFromFlattenedIndex() {
    self.ugrid.resize(Size(width: 20, height: 10))
    expect(self.ugrid.position(from: 0))
      .to(equal(Position(row: 0, column: 0)))
    expect(self.ugrid.position(from: 5))
      .to(equal(Position(row: 0, column: 5)))
    expect(self.ugrid.position(from: 20))
      .to(equal(Position(row: 1, column: 0)))
    expect(self.ugrid.position(from: 25))
      .to(equal(Position(row: 1, column: 5)))
    expect(self.ugrid.position(from: 180))
      .to(equal(Position(row: 9, column: 0)))
    expect(self.ugrid.position(from: 199))
      .to(equal(Position(row: 9, column: 19)))
    expect(self.ugrid.position(from: 418))
      .to(equal(Position(row: 9, column: 18)))
    expect(self.ugrid.position(from: 419))
      .to(equal(Position(row: 9, column: 19)))
  }

  func testLeftBoundaryOfWord() {
    self.ugrid.resize(Size(width: 10, height: 2))
    self.ugrid.update(row: 0,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: " 12 45678 ".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))

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

    self.ugrid.update(row: 1,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: "0123456789".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))

    expect(self.ugrid.leftBoundaryOfWord(at: Position(row: 1, column: 0)))
      .to(equal(0))
  }

  func testRightBoundaryOfWord() {
    self.ugrid.resize(Size(width: 10, height: 2))
    self.ugrid.update(row: 0,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: " 12345 78 ".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))

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

    self.ugrid.update(row: 1,
                      startCol: 0,
                      endCol: 10,
                      clearCol: 10,
                      clearAttr: 0,
                      chunk: "0123456789".compactMap { String($0) },
                      attrIds: Array<Int>(repeating: 0, count: 10))
    expect(self.ugrid.rightBoundaryOfWord(at: Position(row: 1, column: 9)))
      .to(equal(9))
  }
}
