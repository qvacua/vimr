//
// Created by Tae Won Ha on 25.08.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Cocoa

// FIXME: GH-666: Delete
struct OldCellAttributes: CustomStringConvertible, Equatable {

  var fontTrait: FontTrait
  var foreground: Int
  var background: Int
  var special: Int
  var reverse: Bool

  public static var debug: OldCellAttributes {
    return OldCellAttributes(fontTrait: [], foreground: 0, background: 0, special: 0, reverse: false)
  }

  public static func ==(left: OldCellAttributes, right: OldCellAttributes) -> Bool {
    if left.foreground != right.foreground { return false }
    if left.background != right.background { return false }
    if left.special != right.special { return false }

    if left.fontTrait != right.fontTrait { return false }
    if left.reverse != right.reverse { return false }

    return true
  }

  public var effectiveForeground: Int {
    return self.reverse ? self.background : self.foreground
  }

  public var effectiveBackground: Int {
    return self.reverse ? self.foreground : self.background
  }

  public var description: String {
    return "CellAttributes<" +
      "trait: \(String(self.fontTrait.rawValue, radix: 2)), " +
      "fg: \(String(self.foreground, radix: 16)), " +
      "bg: \(String(self.background, radix: 16)), " +
      "sp: \(String(self.special, radix: 16)), " +
      "reverse: \(self.reverse)" +
      ">"
  }

  public var inverted: OldCellAttributes {
    var result = self

    result.background = self.foreground
    result.foreground = self.background

    return result
  }
}
