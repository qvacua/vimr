/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

struct Cell: CustomStringConvertible {
  
  fileprivate let attributes: CellAttributes

  let string: String
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
    return self.string.characters.count > 0 ? self.string : "*"
  }
}

extension Position: CustomStringConvertible, Equatable {
  
  static let zero = Position(row: 0, column: 0)
  static let null = Position(row: -1, column: -1)
  
  public var description: String {
    return "Position<\(self.row):\(self.column)>"
  }
}

public func == (left: Position, right: Position) -> Bool {
  if left.row != right.row { return false }
  if left.column != right.column { return false }
  
  return true
}

struct Size: CustomStringConvertible, Equatable {
  
  static let zero = Size(width: 0, height: 0)
  
  let width: Int
  let height: Int

  var description: String {
    return "Size<\(self.width):\(self.height)>"
  }
}

func == (left: Size, right: Size) -> Bool {
  return left.width == right.width && left.height == right.height
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

  var rowRange: CountableClosedRange<Int> {
    return self.top...self.bottom
  }

  var columnRange: CountableClosedRange<Int> {
    return self.left...self.right
  }
}

/// Almost a verbatim copy of ugrid.c of NeoVim
class Grid: CustomStringConvertible {

  fileprivate let lock = NSRecursiveLock()

  fileprivate(set) var region = Region.zero
  fileprivate(set) var size = Size.zero
  fileprivate(set) var putPosition = Position.zero
  fileprivate(set) var screenCursor = Position.zero
  
  var foreground = qDefaultForeground
  var background = qDefaultBackground
  var special = qDefaultSpecial
  
  var attrs: CellAttributes = CellAttributes(
    fontTrait: .none,
    foreground: qDefaultForeground, background: qDefaultBackground, special: qDefaultSpecial
  )
  
  fileprivate(set) var cells: [[Cell]] = []

  var hasData: Bool {
    lock.lock()
    let result = !self.cells.isEmpty
    lock.unlock()

    return result
  }
  
  var description: String {
    return self.cells.reduce("<<< Grid\n") { $1.reduce($0) { $0 + $1.description } + "\n" } + ">>>"
  }
  
  func resize(_ size: Size) {
    lock.lock()
    self.region = Region(top: 0, bottom: size.height - 1, left: 0, right: size.width - 1)
    self.size = size
    self.putPosition = Position.zero
    
    let emptyCellAttrs = CellAttributes(fontTrait: .none,
                                        foreground: self.foreground, background: self.background, special: self.special)
    
    let emptyRow = Array(repeating: Cell(string: " ", attrs: emptyCellAttrs), count: size.width)
    self.cells = Array(repeating: emptyRow, count: size.height)
    lock.unlock()
  }
  
  func clear() {
    lock.lock()
    self.clearRegion(self.region)
    lock.unlock()
  }
  
  func eolClear() {
    self.clearRegion(
      Region(top: self.putPosition.row, bottom: self.putPosition.row,
             left: self.putPosition.column, right: self.region.right)
    )
  }
  
  func setScrollRegion(_ region: Region) {
    lock.lock()
    self.region = region
    lock.unlock()
  }
  
  func scroll(_ count: Int) {
    lock.lock()
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
    lock.unlock()
  }
  
  func goto(_ position: Position) {
    lock.lock()
    self.putPosition = position
    lock.unlock()
  }
  
  func moveCursor(_ position: Position) {
    lock.lock()
    self.screenCursor = position
    lock.unlock()
  }
  
  func put(_ string: String) {
    lock.lock()
    // FIXME: handle the following situation:
    // |abcde | <- type ㅎ
    // =>
    // |abcde>| <- ">" at the end of the line is wrong -> the XPC could tell the main app whether the string occupies
    // |ㅎ    |        two cells using vim_strwidth()
    self.cells[self.putPosition.row][self.putPosition.column] = Cell(string: string, attrs: self.attrs)
    
    // Increment the column of the put position because neovim calls sets the position only once when drawing
    // consecutive cells in the same line
    self.putPosition.column += 1
    lock.unlock()
  }

  func putMarkedText(_ string: String) {
    lock.lock()
    // NOTE: Maybe there's a better way to indicate marked text than inverting...
    self.cells[self.putPosition.row][self.putPosition.column] = Cell(string: string, attrs: self.attrs, marked: true)
    self.putPosition.column += 1
    lock.unlock()
  }

  func unmarkCell(_ position: Position) {
    lock.lock()
    //    NSLog("\(#function): \(position)")
    self.cells[position.row][position.column].marked = false
    lock.unlock()
  }

  func singleIndexFrom(_ position: Position) -> Int {
    lock.lock()
    let result = position.row * self.size.width + position.column
    lock.unlock()

    return result
  }

  func regionOfWord(at position: Position) -> Region {
    lock.lock()
    let row = position.row
    let column = position.column

    guard row < self.size.height else {
      lock.unlock()
      return Region.zero
    }

    guard column < self.size.width else {
      lock.unlock()
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
    lock.unlock()

    return Region(top: row, bottom: row, left: left, right: right)
  }

  func positionFromSingleIndex(_ idx: Int) -> Position {
    lock.lock()
    let row = Int(floor(Double(idx) / Double(self.size.width)))
    let column = idx - row * self.size.width
    lock.unlock()

    return Position(row: row, column: column)
  }

  func isCellEmpty(_ position: Position) -> Bool {
    lock.lock()
    guard self.isSane(position: position) else {
      lock.unlock()
      return false
    }

    if self.cells[position.row][position.column].string.characters.count == 0 {
      lock.unlock()
      return true
    }

    lock.unlock()
    return false
  }

  func isPreviousCellEmpty(_ position: Position) -> Bool {
    lock.lock()
    let result = self.isCellEmpty(self.previousCellPosition(position))
    lock.unlock()

    return result
  }

  func isNextCellEmpty(_ position: Position) -> Bool {
    lock.lock()
    let result = self.isCellEmpty(self.nextCellPosition(position))
    lock.unlock()

    return result
  }

  func previousCellPosition(_ position: Position) -> Position {
    lock.lock()
    let result = Position(row: position.row, column: max(position.column - 1, 0))
    lock.unlock()

    return result
  }
  
  func nextCellPosition(_ position: Position) -> Position {
    lock.lock()
    let result = Position(row: position.row, column: min(position.column + 1, self.size.width - 1))
    lock.unlock()

    return result
  }
  
  func cellForSingleIndex(_ idx: Int) -> Cell {
    lock.unlock()
    let position = self.positionFromSingleIndex(idx)
    let result = self.cells[position.row][position.column]
    lock.unlock()

    return result
  }

  fileprivate func clearRegion(_ region: Region) {
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

  fileprivate func isSane(position: Position) -> Bool {
    guard position.row < self.size.height && position.column < self.size.width else {
      return false
    }

    return true
  }
}
