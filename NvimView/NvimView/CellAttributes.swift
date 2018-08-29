/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

struct CellAttributes: CustomStringConvertible, Equatable {

  public static func ==(left: CellAttributes, right: CellAttributes) -> Bool {
    if left.foreground != right.foreground { return false }
    if left.background != right.background { return false }
    if left.special != right.special { return false }

    if left.fontTrait != right.fontTrait { return false }
    if left.reverse != right.reverse { return false }

    return true
  }

  var fontTrait: FontTrait

  var foreground: Int
  var background: Int
  var special: Int
  var reverse: Bool

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

  public var inverted: CellAttributes {
    var result = self

    result.background = self.foreground
    result.foreground = self.background

    return result
  }

  func replacingDefaults(
    with defaultAttributes: CellAttributes
  ) -> CellAttributes {
    var result = self
    if self.foreground == -1 {
      result.foreground = defaultAttributes.foreground
    }

    if self.background == -1 {
      result.background = defaultAttributes.background
    }

    if self.special == -1 {
      result.special = defaultAttributes.special
    }

    return result
  }
}
