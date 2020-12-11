/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public struct Position: CustomStringConvertible, Equatable {
  public static let zero = Position(row: 0, column: 0)
  public static let null = Position(row: -1, column: -1)

  // FIXME: GH-666: Delete
  public static let beginning = Position(row: 1, column: 1)

  public static func == (left: Position, right: Position) -> Bool {
    if left.row != right.row { return false }
    if left.column != right.column { return false }

    return true
  }

  public var row: Int
  public var column: Int

  public init(row: Int, column: Int) {
    self.row = row
    self.column = column
  }

  public var description: String { "Position<\(self.row):\(self.column)>" }

  public func advancing(row dy: Int, column dx: Int) -> Position {
    Position(row: self.row + dy, column: self.column + dx)
  }
}

struct Size: CustomStringConvertible, Equatable {
  static let zero = Size(width: 0, height: 0)

  static func == (left: Size, right: Size) -> Bool {
    left.width == right.width && left.height == right.height
  }

  var width: Int
  var height: Int

  var description: String { "Size<\(self.width):\(self.height)>" }
}

struct Region: CustomStringConvertible {
  static let zero = Region(top: 0, bottom: 0, left: 0, right: 0)

  var top: Int
  var bottom: Int
  var left: Int
  var right: Int

  var description: String {
    "Region<\(self.top)...\(self.bottom):\(self.left)...\(self.right)>"
  }

  var rowRange: CountableClosedRange<Int> { self.top...self.bottom }

  var columnRange: CountableClosedRange<Int> { self.left...self.right }
}
