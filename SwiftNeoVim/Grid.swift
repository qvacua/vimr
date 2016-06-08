/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

/// Almost a verbatim copy of ugrid.c of NeoVim
struct Cell: CustomStringConvertible {
  let string: String
  let attrs: HighlightAttributes
  
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
    return "Region<\(self.top),\(self.bottom):\(self.left),\(self.right)>"
  }
}

class Grid: CustomStringConvertible {
  
  private static let qEmptyHighlightAttributes = HighlightAttributes(
    bold: false, underline: false, undercurl: false, italic: false,
    reverse: false, foreground: -1, background: -1, special: -1
  )
  
  private(set) var region = Region.zero
  private(set) var size = Size.zero
  private(set) var position = Position.zero
  
  var foreground: Int32 = -1
  var background: Int32 = -1
  var special: Int32 = -1
  
  var attrs: HighlightAttributes = Grid.qEmptyHighlightAttributes
  
  private(set) var cells: [[Cell]] = []
  
  var description: String {
    return self.cells.reduce("<<< Grid\n") { $1.reduce($0) { $0 + $1.description } + "\n" } + ">>>"
  }
  
  func resize(size: Size) {
    self.region = Region(top: 0, bottom: size.height - 1, left: 0, right: size.width - 1)
    self.size = size
    self.position = Position.zero
    
    let emptyRow = Array(count: size.width, repeatedValue: Cell(string: " ", attrs: Grid.qEmptyHighlightAttributes))
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
    // TODO: implement me
  }
  
  func goto(position: Position) {
    self.position = position
  }
  
  func put(string: String) {
    self.cells[self.position.row][self.position.column] = Cell(string: string, attrs: self.attrs)
    self.position.column += 1
  }
  
  private func clearRegion(region: Region) {
    guard self.region.bottom > 0 && self.region.right > 0 && region.bottom > 0 && region.right > 0 else {
      return
    }

    let clearedAttrs = HighlightAttributes(
      bold: false, underline: false, undercurl: false, italic: false,
      reverse: false, foreground: self.foreground, background: self.background, special: self.background
    )
    
    let clearedCell = Cell(string: " ", attrs: clearedAttrs)
    let clearedRow = Array(count: region.right - region.left + 1, repeatedValue: clearedCell)
    for i in region.top...region.bottom {
      self.cells[i].replaceRange(region.left...region.right, with: clearedRow)
    }
  }
}