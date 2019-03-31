/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

struct UCell: Codable {

  var string: String
  var attrId: Int

  var flatCharIndex: Int

  init(string: String, attrId: Int, flatCharIndex: Int = 0) {
    self.string = string
    self.attrId = attrId
    self.flatCharIndex = flatCharIndex
  }
}

final class UGrid: CustomStringConvertible, Codable {

  private(set) var cursorPosition = Position.zero

  private(set) var size = Size.zero

  private(set) var cells: [[UCell]] = []

  enum CodingKeys: String, CodingKey {

    case width
    case height
    case cells
  }

  init() {
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let width = try values.decode(Int.self, forKey: .width)
    let height = try values.decode(Int.self, forKey: .height)
    self.size = Size(width: width, height: height)

    self.cells = try values.decode([[UCell]].self, forKey: .cells)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(self.size.width, forKey: .width)
    try container.encode(self.size.height, forKey: .height)

    try container.encode(self.cells, forKey: .cells)
  }

  #if DEBUG
  func dump() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    let data = try encoder.encode(self)
    try data.write(to: URL(fileURLWithPath: "/tmp/ugrid.dump.json"))
  }
  #endif

  var description: String {
    let result = "UGrid.flatCharIndex:\n" + self.cells.reduce("") { result, row in
      return result + "(\(row[0].flatCharIndex...row[self.size.width - 1].flatCharIndex)), "
    }

    return result
  }
  var hasData: Bool {
    return !self.cells.isEmpty
  }

  func unmarkCell(at position: Position) {
    let attrId = self.cells[position.row][position.column].attrId

    guard attrId < CellAttributesCollection.defaultAttributesId
          || attrId == CellAttributesCollection.reversedDefaultAttributesId
      else {
      return
    }

    let newAttrsId: Int
    if attrId == CellAttributesCollection.reversedDefaultAttributesId {
      newAttrsId = CellAttributesCollection.defaultAttributesId
    } else {
      newAttrsId = abs(attrId)
    }
    self.cells[position.row][position.column].attrId = newAttrsId

    if self.isNextCellEmpty(position) {
      self.cells[position.row][position.column + 1].attrId = newAttrsId
    }
  }

  func markCell(at position: Position) {
    let attrId = self.cells[position.row][position.column].attrId

    guard attrId >= CellAttributesCollection.defaultAttributesId
          && attrId != CellAttributesCollection.reversedDefaultAttributesId
      else {
      return
    }

    let newAttrsId: Int
    if attrId == CellAttributesCollection.defaultAttributesId {
      newAttrsId = CellAttributesCollection.reversedDefaultAttributesId
    } else {
      newAttrsId = (-1) * attrId
    }
    self.cells[position.row][position.column].attrId = newAttrsId

    if self.isNextCellEmpty(position) {
      self.cells[position.row][position.column + 1].attrId = newAttrsId
    }
  }

  func position(fromOneDimCellIndex flattenedIndex: Int) -> Position {
    let row = min(
      self.size.height - 1,
      max(0, Int(floor(Double(flattenedIndex) / Double(self.size.width))))
    )
    let col = min(
      self.size.width - 1,
      max(0, flattenedIndex % self.size.width)
    )

    return Position(row: row, column: col)
  }

  func oneDimCellIndex(forRow row: Int, column: Int) -> Int {
    return row * self.size.width + column
  }

  func oneDimCellIndex(forPosition position: Position) -> Int {
    return position.row * self.size.width + position.column
  }

  func flatCharIndex(forPosition position: Position) -> Int {
    return self.cells[position.row][position.column].flatCharIndex
  }

  func firstPosition(fromFlatCharIndex index: Int) -> Position? {
    for (rowIndex, row) in self.cells.enumerated() {
      if let column = row.firstIndex(where: { $0.flatCharIndex == index }) {
        return Position(row: rowIndex, column: column)
      }
    }

    return nil
  }

  func lastPosition(fromFlatCharIndex index: Int) -> Position? {
    for (rowIndex, row) in self.cells.enumerated() {
      if let column = row.lastIndex(where: { $0.flatCharIndex == index }) {
        return Position(row: rowIndex, column: column)
      }
    }

    return nil
  }

  func leftBoundaryOfWord(at position: Position) -> Int {
    let column = position.column
    let row = self.cells[position.row]

    if row[column].string == wordSeparator {
      return column
    }

    for i in (0..<column).reversed() {
      if row[i].string == wordSeparator {
        return min(i + 1, self.size.width - 1)
      }
    }

    return 0
  }

  func rightBoundaryOfWord(at position: Position) -> Int {
    let column = position.column
    let row = self.cells[position.row]

    if row[column].string == wordSeparator {
      return column
    }

    if column + 1 == self.size.width {
      return column
    }

    for i in (column + 1)..<self.size.width {
      if row[i].string == wordSeparator {
        return max(i - 1, 0)
      }
    }

    return self.size.width - 1
  }

  func goto(_ position: Position) {
    self.cursorPosition = position
  }

  func scroll(
    region: Region,
    rows: Int,
    cols: Int
  ) {
    var start, stop, step: Int
    if rows > 0 {
      start = region.top;
      stop = region.bottom - rows + 1;
      step = 1;
    } else {
      start = region.bottom;
      stop = region.top - rows - 1;
      step = -1;
    }

    // copy cell data
    let rangeWithinRow = region.left...region.right
    for i in stride(from: start, to: stop, by: step) {
      self.cells[i].replaceSubrange(
        rangeWithinRow, with: self.cells[i + rows][rangeWithinRow]
      )
    }

    // clear cells in the emptied region,
    var clearTop, clearBottom: Int
    if rows > 0 {
      clearTop = stop
      clearBottom = stop + rows - 1
    } else {
      clearBottom = stop
      clearTop = stop + rows + 1
    }

    self.clear(region: Region(
      top: clearTop,
      bottom: clearBottom,
      left: region.left,
      right: region.right
    ))
  }

  func isNextCellEmpty(_ position: Position) -> Bool {
    guard self.isSane(position) else { return false }
    guard position.column + 1 < self.size.width else { return false }
    guard !self.cells[position.row][position.column].string.isEmpty else {
      return false
    }

    if self.cells[position.row][position.column + 1].string.isEmpty {
      return true
    }

    return false
  }

  func isSane(_ position: Position) -> Bool {
    if position.column < 0
       || position.column >= self.size.width
       || position.row < 0
       || position.row >= self.size.height {
      return false
    }

    return true
  }

  func clear() {
    let emptyRow = Array(
      repeating: UCell(string: clearString,
                       attrId: CellAttributesCollection.defaultAttributesId),
      count: size.width
    )
    self.cells = Array(repeating: emptyRow, count: size.height)
  }

  func clear(region: Region) {
    // FIXME: sometimes clearRegion gets called without first resizing the Grid.
    // Should we handle this?
    guard self.hasData else {
      return
    }

    let clearedCell = UCell(
      string: " ",
      attrId: CellAttributesCollection.defaultAttributesId
    )
    let clearedRow = Array(
      repeating: clearedCell, count: region.right - region.left + 1
    )
    for i in region.top...region.bottom {
      self.cells[i].replaceSubrange(
        region.left...region.right, with: clearedRow
      )
    }
  }

  func resize(_ size: Size) {
    self.log.debug(size)

    self.size = size
    self.cursorPosition = .zero

    self.clear()
  }

  /// endCol and clearCol are past last index
  /// This does not recompute the flat char indices. For performance it's done
  /// in NvimView.flush()
  func update(
    row: Int,
    startCol: Int,
    endCol: Int,
    clearCol: Int,
    clearAttr: Int,
    chunk: [String],
    attrIds: [Int]
  ) {
    for column in startCol..<endCol {
      self.cells[row][column].string = chunk[column - startCol]
      self.cells[row][column].attrId = attrIds[column - startCol]
    }

    if clearCol > endCol {
      cells[row].replaceSubrange(
        endCol..<clearCol,
        with: Array(
          repeating: UCell(string: clearString, attrId: clearAttr),
          count: clearCol - endCol
        )
      )
    }
  }

  func recomputeFlatIndices(rowStart: Int, rowEndInclusive: Int) {
    self.log.debug("Recomputing flat indices from row \(rowStart)")

    var delta = 0
    if rowStart > 0 {
      delta = self.cells[rowStart - 1][self.size.width - 1].flatCharIndex
              - self.oneDimCellIndex(forRow: rowStart - 1,
                                     column: self.size.width - 1)
    }

    for row in rowStart...rowEndInclusive {
      for column in 0..<self.size.width {
        if self.cells[row][column].string.isEmpty {
          delta -= 1
        }
        self.cells[row][column].flatCharIndex
        = self.oneDimCellIndex(forRow: row, column: column) + delta
      }
    }
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.view)
}

private let clearString = " "
private let wordSeparator = " "
