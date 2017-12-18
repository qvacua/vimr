/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

private let defaultForeground: Int = 0xFF000000
private let defaultBackground: Int = 0xFFFFFFFF
private let defaultSpecial: Int = 0xFFFF0000

struct Cell: CustomStringConvertible {

  private let attributes: CellAttributes

  var string: String
  var marked: Bool

  var attrs: CellAttributes {
    return self.marked ? self.attributes.inverted : self.attributes
  }

  init(string: String, attrs: CellAttributes, marked: Bool = false) {
    self.string = string
    self.attributes = attrs
    self.marked = marked
  }

  var description: String {
    return self.string.count > 0 ? self.string : "*"
  }
}

extension Position: CustomStringConvertible, Equatable {

  static let zero = Position(row: 0, column: 0)
  static let null = Position(row: -1, column: -1)

  public static func ==(left: Position, right: Position) -> Bool {
    if left.row != right.row { return false }
    if left.column != right.column { return false }

    return true
  }

  public var description: String {
    return "Position<\(self.row):\(self.column)>"
  }
}

struct Size: CustomStringConvertible, Equatable {

  static let zero = Size(width: 0, height: 0)

  static func ==(left: Size, right: Size) -> Bool {
    return left.width == right.width && left.height == right.height
  }

  var width: Int
  var height: Int

  var description: String {
    return "Size<\(self.width):\(self.height)>"
  }
}

struct Region: CustomStringConvertible {

  static let zero = Region(top: 0, bottom: 0, left: 0, right: 0)

  var top: Int
  var bottom: Int
  var left: Int
  var right: Int

  var description: String {
    return "Region<\(self.top)...\(self.bottom):\(self.left)...\(self.right)>"
  }

  var rowRange: CountableClosedRange<Int> {
    return self.top...self.bottom
  }

  var columnRange: CountableClosedRange<Int> {
    return self.left...self.right
  }
}

/// Almost a verbatim copy of ugrid.c of NeoVim
class Grid: CustomStringConvertible {

  private(set) var region = Region.zero
  private(set) var size = Size.zero
  private(set) var position = Position.zero

  var foreground = defaultForeground
  var background = defaultBackground
  var special = defaultSpecial

  var attrs: CellAttributes = CellAttributes(
    fontTrait: .none,
    foreground: defaultForeground, background: defaultBackground, special: defaultSpecial
  )

  private(set) var cells: [[Cell]] = []

  var hasData: Bool {
    return !self.cells.isEmpty
  }

  var description: String {
    return self.cells.reduce("<<< Grid\n") { $1.reduce($0) { $0 + $1.description } + "\n" } + ">>>"
  }

  func resize(_ size: Size) {
    self.region = Region(top: 0, bottom: size.height - 1, left: 0, right: size.width - 1)
    self.size = size
    self.position = Position.zero

    let emptyCellAttrs = CellAttributes(fontTrait: .none,
                                        foreground: self.foreground, background: self.background, special: self.special)

    let emptyRow = Array(repeating: Cell(string: " ", attrs: emptyCellAttrs), count: size.width)
    self.cells = Array(repeating: emptyRow, count: size.height)
  }

  func clear() {
    self.clearRegion(self.region)
  }

  func eolClear() {
    self.clearRegion(
      Region(top: self.position.row, bottom: self.position.row,
             left: self.position.column, right: self.region.right)
    )
  }

  func setScrollRegion(_ region: Region) {
    self.region = region
  }

  func scroll(_ count: Int) {
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
    for i in stride(from: start, to: stop, by: step) {
      self.cells[i].replaceSubrange(rangeWithinRow, with: self.cells[i + count][rangeWithinRow])
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

  func goto(_ position: Position) {
    self.position = position
  }

  func put(_ string: String) {
    // FIXME: handle the following situation:
    // |abcde | <- type ㅎ
    // =>
    // |abcde>| <- ">" at the end of the line is wrong -> the XPC could tell the main app whether the string occupies
    // |ㅎ    |        two cells using vim_strwidth()
    self.cells[self.position.row][self.position.column] = Cell(string: string, attrs: self.attrs)

    // Increment the column of the put position because neovim calls sets the position only once when drawing
    // consecutive cells in the same line
    self.advancePosition()
  }

  func putMarkedText(_ string: String) {
    // NOTE: Maybe there's a better way to indicate marked text than inverting...
    self.cells[self.position.row][self.position.column] = Cell(string: string, attrs: self.attrs, marked: true)
    self.advancePosition()
  }

  func unmarkCell(_ position: Position) {
//    NSLog("\(#function): \(position)")
    self.cells[position.row][position.column].marked = false
  }

  func singleIndexFrom(_ position: Position) -> Int {
    return position.row * self.size.width + position.column
  }

  func regionOfWord(at position: Position) -> Region {
    let row = position.row
    let column = position.column

    guard row < self.size.height else {
      return Region.zero
    }

    guard column < self.size.width else {
      return Region.zero
    }

    var left = 0
    for idx in (0..<column).reversed() {
      let cell = self.cells[row][idx]
      if cell.string == " " {
        left = idx + 1
        break
      }
    }

    var right = self.size.width - 1
    for idx in (column + 1)..<self.size.width {
      let cell = self.cells[row][idx]
      if cell.string == " " {
        right = idx - 1
        break
      }
    }

    return Region(top: row, bottom: row, left: left, right: right)
  }

  func positionFromSingleIndex(_ idx: Int) -> Position {
    let row = Int(floor(Double(idx) / Double(self.size.width)))
    let column = idx - row * self.size.width

    return Position(row: row, column: column)
  }

  func isCellEmpty(_ position: Position) -> Bool {
    guard self.isSane(position: position) else {
      return false
    }

    if self.cells[position.row][position.column].string.count == 0 {
      return true
    }

    return false
  }

  func isPreviousCellEmpty(_ position: Position) -> Bool {
    return self.isCellEmpty(self.previousCellPosition(position))
  }

  func isNextCellEmpty(_ position: Position) -> Bool {
    return self.isCellEmpty(self.nextCellPosition(position))
  }

  func previousCellPosition(_ position: Position) -> Position {
    return Position(row: position.row, column: max(position.column - 1, 0))
  }

  func nextCellPosition(_ position: Position) -> Position {
    return Position(row: position.row, column: min(position.column + 1, self.size.width - 1))
  }

  func cellForSingleIndex(_ idx: Int) -> Cell {
    let position = self.positionFromSingleIndex(idx)
    return self.cells[position.row][position.column]
  }

  private func clearRegion(_ region: Region) {
    // FIXME: sometimes clearRegion gets called without first resizing the Grid. Should we handle this?
    guard self.hasData else {
      return
    }

    let clearedAttrs = CellAttributes(fontTrait: .none,
                                      foreground: self.foreground, background: self.background, special: self.special)

    let clearedCell = Cell(string: " ", attrs: clearedAttrs)
    let clearedRow = Array(repeating: clearedCell, count: region.right - region.left + 1)
    for i in region.top...region.bottom {
      self.cells[i].replaceSubrange(region.left...region.right, with: clearedRow)
    }
  }

  private func isSane(position: Position) -> Bool {
    guard position.row < self.size.height && position.column < self.size.width else {
      return false
    }

    return true
  }

  private func advancePosition() {
    self.position.column += 1
    if self.position.column >= self.size.width {
      self.position.column -= 1
    }
  }
}
