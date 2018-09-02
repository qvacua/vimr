/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

struct UCell {

  var string: String
  var attrId: Int
}

final class UGrid {

  private(set) var size = Size.zero
  private(set) var posision = Position.zero

  private(set) var cells: [[UCell]] = []

  var hasData: Bool {
    return !self.cells.isEmpty
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

  func clear() {
    let emptyRow = Array(
      repeating: UCell(string: clearString, attrId: defaultAttrId),
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
    logger.debug(size)

    self.size = size
    self.posision = .zero

    self.clear()
  }

  // endCol and clearCol are past last index
  func update(
    row: Int,
    startCol: Int,
    endCol: Int,
    clearCol: Int,
    clearAttr: Int,
    chunk: [String],
    attrIds: [Int]
  ) {
    let newCells = zip(chunk, attrIds).map { element in
      UCell(string: element.0, attrId: element.1)
    }
    self.cells[row].replaceSubrange(startCol..<endCol, with: newCells)

    if clearCol > endCol {
      cells[row].replaceSubrange(
        endCol..<clearCol,
        with: Array(repeating: UCell(string: clearString, attrId: clearAttr),
                    count: clearCol - endCol)
      )
    }
  }
}

private let clearString = " "
private let wordSeparator = " "
private let defaultAttrId = -1
