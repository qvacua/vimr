//
// Created by Tae Won Ha on 25.08.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Cocoa

public struct Position: CustomStringConvertible, Equatable {

  public static let zero = Position(row: 0, column: 0)
  public static let null = Position(row: -1, column: -1)

  public static func ==(left: Position, right: Position) -> Bool {
    if left.row != right.row { return false }
    if left.column != right.column { return false }

    return true
  }

  public var row: Int
  public var column: Int

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
