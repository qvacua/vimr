/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

struct UUpdate: Codable {
  var string: String
  var attrId: Int?
  var repeats: Int?

  var utf16chars: [Unicode.UTF16.CodeUnit]

  init(string: String, attrId: Int? = nil, repeats: Int? = nil) {
    self.string = string
    self.attrId = attrId
    self.repeats = repeats

    self.utf16chars = Array(string.utf16)
  }
}

struct UCell: Codable {
  var string: String
  var attrId: Int

  // When computing FontGlueRun, we have to convert the UCell.string to array of UTF16 chars.
  // The conversion takes almost half of AttributesRunDrawer.fontGlyphRuns().
  // So, we cache it in the cell to compute it only once when scrolling.
  var utf16chars: [Unicode.UTF16.CodeUnit]

  var flatCharIndex: Int

  init(string: String, attrId: Int, flatCharIndex: Int = 0) {
    self.string = string
    self.attrId = attrId

    self.utf16chars = Array(string.utf16)

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

  init() {}

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

  var description: String {
    let result = "UGrid.flatCharIndex:\n" + self.cells.reduce("") { result, row in
      result + "(\(row[0].flatCharIndex...row[self.size.width - 1].flatCharIndex)), "
    }

    return result
  }

  var hasData: Bool { !self.cells.isEmpty }

  func flatCharIndex(forPosition position: Position) -> Int {
    self.cells[position.row][position.column].flatCharIndex
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

    if row[column].string == wordSeparator { return column }

    for i in (0..<column).reversed() {
      if row[i].string == wordSeparator { return min(i + 1, self.size.width - 1) }
    }

    return 0
  }

  func rightBoundaryOfWord(at position: Position) -> Int {
    let column = position.column
    let row = self.cells[position.row]

    if row[column].string == wordSeparator { return column }

    if column + 1 == self.size.width { return column }

    for i in (column + 1)..<self.size.width {
      if row[i].string == wordSeparator { return max(i - 1, 0) }
    }

    return self.size.width - 1
  }

  func goto(_ position: Position) { self.cursorPosition = position }

  func scroll(region: Region, rows: Int, cols _: Int) {
    var start, stop, step: Int
    if rows > 0 {
      start = region.top
      stop = region.bottom - rows + 1
      step = 1
    } else {
      start = region.bottom
      stop = region.top - rows - 1
      step = -1
    }
    var oldMarkedInfo: MarkedInfo?
    if let row = self.markedInfo?.position.row, region.top <= row, row <= region.bottom {
      oldMarkedInfo = self.popMarkedInfo()
    }
    defer {
      // keep markedInfo position not changed. markedInfo only following cursor position change
      if let oldMarkedInfo {
        updateMarkedInfo(newValue: oldMarkedInfo)
      }
    }

    // copy cell data
    let rangeWithinRow = region.left...region.right
    for i in stride(from: start, to: stop, by: step) {
      self.cells[i].replaceSubrange(rangeWithinRow, with: self.cells[i + rows][rangeWithinRow])
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
    guard !self.cells[position.row][position.column].string.isEmpty else { return false }

    if self.cells[position.row][position.column + 1].string.isEmpty { return true }

    return false
  }

  func isSane(_ position: Position) -> Bool {
    if position.column < 0
      || position.column >= self.size.width
      || position.row < 0
      || position.row >= self.size.height
    { return false }

    return true
  }

  func clear() {
    let emptyRow = Array(
      repeating: UCell(string: clearString, attrId: CellAttributesCollection.defaultAttributesId),
      count: self.size.width
    )
    self.updateMarkedInfo(newValue: nil) // everything need to be reset
    self.cells = Array(repeating: emptyRow, count: self.size.height)
  }

  func clear(region: Region) {
    // FIXME: sometimes clearRegion gets called without first resizing the Grid.
    // Should we handle this?
    guard self.hasData else { return }

    let clearedCell = UCell(string: " ", attrId: CellAttributesCollection.defaultAttributesId)
    let clearedRow = Array(repeating: clearedCell, count: region.right - region.left + 1)
    for i in region.top...region.bottom {
      self.cells[i].replaceSubrange(region.left...region.right, with: clearedRow)
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
    // remove marked patch and recover after modified from vim
    var oldMarkedInfo: MarkedInfo?
    if row == self.markedInfo?.position.row {
      oldMarkedInfo = self.popMarkedInfo()
    }
    defer {
      if let oldMarkedInfo {
        updateMarkedInfo(newValue: oldMarkedInfo)
      }
    }
    for column in startCol..<endCol {
      let idx = column - startCol
      self.cells[row][column].string = chunk[idx]
      self.cells[row][column].utf16chars = Array(chunk[idx].utf16)
      self.cells[row][column].attrId = attrIds[idx]
    }

    if clearCol > endCol {
      self.cells[row].replaceSubrange(
        endCol..<clearCol,
        with: Array(
          repeating: UCell(string: clearString, attrId: clearAttr),
          count: clearCol - endCol
        )
      )
    }
  }

  /// This does not recompute the flat char indices. For performance it's done
  /// in NvimView.flush()
  func updateNu(
    row: Int,
    startCol: Int,
    chunk: [UUpdate]
  ) -> Int {
    // remove marked patch and recover after modified from vim
    var oldMarkedInfo: MarkedInfo?
    if row == self.markedInfo?.position.row {
      oldMarkedInfo = self.popMarkedInfo()
    }
    defer {
      if let oldMarkedInfo {
        updateMarkedInfo(newValue: oldMarkedInfo)
      }
    }
    var lastAttrId = 0
    var column = startCol
    for cindex in 0..<chunk.count {
      let reps = chunk[cindex].repeats ?? 1
      for _ in 0..<reps {
        self.cells[row][column].string = chunk[cindex].string
        self.cells[row][column].utf16chars = chunk[cindex].utf16chars
        let attrId = chunk[cindex].attrId
        if attrId != nil {
          lastAttrId = attrId!
        }
        self.cells[row][column].attrId = lastAttrId
        column += 1
      }
    }
    return column
  }

  struct MarkedInfo {
    var position: Position
    var markedCell: [UCell]
    var selectedRange: NSRange // begin from markedCell and calculate by ucell count
  }

  var _markedInfo: MarkedInfo?
  func popMarkedInfo() -> MarkedInfo? {
    if let markedInfo = _markedInfo {
      // true clear or just popup
      self.updateMarkedInfo(newValue: nil)
      return markedInfo
    }
    return nil
  }

  // return changedRowStart. Int.max if no change
  @discardableResult
  func updateMarkedInfo(newValue: MarkedInfo?) -> Int {
    assert(Thread.isMainThread, "should occur on main thread!")
    var changedRowStart = Int.max
    if let old = _markedInfo {
      self.cells[old.position.row]
        .removeSubrange(old.position.column..<(old.position.column + old.markedCell.count))
      changedRowStart = old.position.row
    }
    self._markedInfo = newValue
    if let new = newValue {
      self.cells[new.position.row].insert(contentsOf: new.markedCell, at: new.position.column)
      changedRowStart = min(changedRowStart, new.position.row)
    }
    return changedRowStart
  }

  var markedInfo: MarkedInfo? {
    get { self._markedInfo }
    set {
      let changedRowStart = self.updateMarkedInfo(newValue: newValue)
      if changedRowStart < self.size.height {
        self.recomputeFlatIndices(rowStart: changedRowStart)
      }
    }
  }

  func cursorPositionWithMarkedInfo(allowOverflow: Bool = false) -> Position {
    var position: Position = self.cursorPosition
    if let markedInfo { position.column += markedInfo.selectedRange.location }
    if !allowOverflow, position.column >= self.size.width { position.column = self.size.width - 1 }
    return position
  }

  // marked text insert into cell directly
  // marked text always following cursor position
  func updateMark(markedText: String, selectedRange: NSRange) {
    assert(Thread.isMainThread)
    var selectedRangeByCell = selectedRange
    let markedTextArray: [String] = markedText.enumerated().reduce(into: []) { array, pair in
      array.append(String(pair.element))
      if !KeyUtils.isHalfWidth(char: pair.element) {
        array.append("")
        if pair.offset < selectedRange.location { selectedRangeByCell.location += 1 }
        else { selectedRangeByCell.length += 1 }
      }
    }
    let cells = markedTextArray.map {
      UCell(string: $0, attrId: CellAttributesCollection.markedAttributesId)
    }
    self.markedInfo = MarkedInfo(
      position: self.cursorPosition,
      markedCell: cells,
      selectedRange: selectedRangeByCell
    )
  }

  func recomputeFlatIndices(rowStart: Int) {
    self.log.debug("Recomputing flat indices from row \(rowStart)")

    var counter = 0
    if rowStart > 0 {
      counter = self.cells[rowStart - 1].last!.flatCharIndex + 1
    }

    // should update following char too since previous line is change
    for row in rowStart...(self.size.height - 1) {
      // marked text may overflow size, counter it too
      for column in self.cells[row].indices {
        if self.cells[row][column].string.isEmpty { counter -= 1 }
        self.cells[row][column].flatCharIndex = counter
        counter += 1
      }
    }
  }

  private let log = Logger(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.view)
}

extension UGrid {
  func dump() throws {
    #if DEBUG
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted

      let data = try encoder.encode(self)
      try data.write(to: URL(fileURLWithPath: "/tmp/ugrid.dump.json"))
    #endif
  }
}

private let clearString = " "
private let wordSeparator = " "
