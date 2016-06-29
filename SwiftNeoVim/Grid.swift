/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

struct Cell: CustomStringConvertible {
  private let attributes: CellAttributes

  let string: String
  var marked: Bool

  var attrs: CellAttributes {
    return self.marked ? self.attributes.reversedColor : self.attributes
  }

  init(string: String, attrs: CellAttributes, marked: Bool = false) {
    self.string = string
    self.attributes = attrs
    self.marked = marked
  }
  
  var description: String {
    return self.string.characters.count > 0 ? self.string : "*"
  }
}

struct Position: CustomStringConvertible {
  
  static let zero = Position(row: 0, column: 0)
  
  var row: Int
  var column: Int

  var description: String {
    return "Position<\(self.row):\(self.column)>"
  }
}

struct Size: CustomStringConvertible {
  
  static let zero = Size(width: 0, height: 0)
  
  let width: Int
  let height: Int

  var description: String {
    return "Size<\(self.width):\(self.height)>"
  }
}

struct Region: CustomStringConvertible {
  
  static let zero = Region(top: 0, bottom: 0, left: 0, right: 0)
  
  let top: Int
  let bottom: Int
  let left: Int
  let right: Int

  var description: String {
    return "Region<\(self.top)...\(self.bottom):\(self.left)...\(self.right)>"
  }

  var rowRange: Range<Int> {
    return self.top...self.bottom
  }

  var columnRange: Range<Int> {
    return self.left...self.right
  }
}

/// Almost a verbatim copy of ugrid.c of NeoVim
class Grid: CustomStringConvertible {
  
  private(set) var region = Region.zero
  private(set) var size = Size.zero
  private(set) var position = Position.zero
  
  var foreground = qDefaultForeground
  var background = qDefaultBackground
  var special = qDefaultSpecial
  
  var attrs: CellAttributes = CellAttributes(
    fontTrait: .None,
    foreground: qDefaultForeground, background: qDefaultBackground, special: qDefaultSpecial
  )
  
  private(set) var cells: [[Cell]] = []

  var hasData: Bool {
    return !self.cells.isEmpty
  }
  
  var description: String {
    return self.cells.reduce("<<< Grid\n") { $1.reduce($0) { $0 + $1.description } + "\n" } + ">>>"
  }
  
  func resize(size: Size) {
    self.region = Region(top: 0, bottom: size.height - 1, left: 0, right: size.width - 1)
    self.size = size
    self.position = Position.zero
    
    let emptyCellAttrs = CellAttributes(fontTrait: .None,
                                        foreground: self.foreground, background: self.background, special: self.special)
    
    let emptyRow = Array(count: size.width, repeatedValue: Cell(string: " ", attrs: emptyCellAttrs))
    self.cells = Array(count: size.height, repeatedValue: emptyRow)
  }
  
  func clear() {
    self.clearRegion(self.region)
  }
  
  func eolClear() {
    self.clearRegion(
      Region(top: self.position.row, bottom: self.position.row, left: self.position.column, right: self.region.right)
    )
  }
  
  func setScrollRegion(region: Region) {
    self.region = region
  }
  
  func scroll(count: Int) {
    var start, stop, step : Int
    if count > 0 {
      start = self.region.top;
      stop = self.region.bottom - count + 1;
      step = 1;
    } else {
      start = self.region.bottom;
      stop = self.region.top - count - 1;
      step = -1;
    }

    // copy cell data
    let rangeWithinRow = self.region.left...self.region.right
    for i in start.stride(to: stop, by: step) {
      self.cells[i].replaceRange(rangeWithinRow, with: self.cells[i + count][rangeWithinRow])
    }

    // clear cells in the emptied region,
    var clearTop, clearBottom: Int
    if count > 0 {
      clearTop = stop
      clearBottom = stop + count - 1
    } else {
      clearBottom = stop
      clearTop = stop + count + 1
    }
    self.clearRegion(Region(top: clearTop, bottom: clearBottom, left: self.region.left, right: self.region.right))
  }
  
  func goto(position: Position) {
    self.position = position
  }
  
  func put(string: String) {
    self.cells[self.position.row][self.position.column] = Cell(string: string, attrs: self.attrs)
    self.position.column += 1
  }

  func putMarkedText(string: String) {
    // NOTE: Maybe there's a better way to indicate marked text than inverting...
    self.cells[self.position.row][self.position.column] = Cell(string: string, attrs: self.attrs, marked: true)
    self.position.column += 1
  }

  func unmarkCell(position: Position) {
    print("!!!!! unmarking: \(position)")
    self.cells[position.row][position.column].marked = false
  }

  func isNextCellEmpty(position: Position) -> Bool {
    if self.cells[position.row][min(position.column + 1, self.size.width - 1)].string.characters.count == 0 {
      return true
    }

    return false
  }

  func nextCellPosition(position: Position) -> Position {
    return Position(row: position.row, column: min(position.column + 1, self.size.width - 1))
  }

  private func clearRegion(region: Region) {
    // FIXME: sometimes clearRegion gets called without first resizing the Grid. Should we handle this?
    guard self.hasData else {
      return
    }

    let clearedAttrs = CellAttributes(fontTrait: .None,
                                      foreground: self.foreground, background: self.background, special: self.special)
    
    let clearedCell = Cell(string: " ", attrs: clearedAttrs)
    let clearedRow = Array(count: region.right - region.left + 1, repeatedValue: clearedCell)
    for i in region.top...region.bottom {
      self.cells[i].replaceRange(region.left...region.right, with: clearedRow)
    }
  }
}
