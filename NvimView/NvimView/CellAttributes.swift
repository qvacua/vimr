/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack

public struct CellAttributes: CustomStringConvertible, Equatable {

  public static func ==(left: CellAttributes, right: CellAttributes) -> Bool {
    if left.foreground != right.foreground { return false }
    if left.background != right.background { return false }
    if left.special != right.special { return false }

    if left.fontTrait != right.fontTrait { return false }
    if left.reverse != right.reverse { return false }

    return true
  }

  public var fontTrait: FontTrait

  public var foreground: Int
  public var background: Int
  public var special: Int

  public var reverse: Bool

  public init(fontTrait: FontTrait, foreground: Int, background: Int, special: Int, reverse: Bool) {
    self.fontTrait = fontTrait
    self.foreground = foreground
    self.background = background
    self.special = special
    self.reverse = reverse
  }
  
  public init(
    withDict dict: [String: MessagePackValue],
    with defaultAttributes: CellAttributes
  ) {
    var fontTrait: FontTrait = []
    if dict["bold"]?.boolValue == true { fontTrait = fontTrait.union(.bold) }
    if dict["italic"]?.boolValue == true { fontTrait = fontTrait.union(.italic) }
    if dict["underline"]?.boolValue == true { fontTrait = fontTrait.union(.underline) }
    if dict["undercurl"]?.boolValue == true { fontTrait = fontTrait.union(.undercurl) }
    self.fontTrait = fontTrait

    self.foreground = dict["foreground"]?.intValue ?? defaultAttributes.foreground
    self.background = dict["background"]?.intValue ?? defaultAttributes.background
    self.special = dict["special"]?.intValue ?? defaultAttributes.special

    self.reverse = dict["reverse"]?.boolValue ?? false
  }

  public var effectiveForeground: Int { self.reverse ? self.background : self.foreground }
  public var effectiveBackground: Int { self.reverse ? self.foreground : self.background }

  public var description: String {
    "CellAttributes<" +
    "trait: \(String(self.fontTrait.rawValue, radix: 2)), " +
    "fg: \(ColorUtils.colorIgnoringAlpha(self.foreground).hex), " +
    "bg: \(ColorUtils.colorIgnoringAlpha(self.background).hex), " +
    "sp: \(ColorUtils.colorIgnoringAlpha(self.special).hex), " +
    "reverse: \(self.reverse)" +
    ">"
  }

  public var reversed: CellAttributes {
    var result = self
    result.reverse = !self.reverse

    return result
  }

  public func replacingDefaults(with defaultAttributes: CellAttributes) -> CellAttributes {
    var result = self

    if self.foreground == -1 { result.foreground = defaultAttributes.effectiveForeground }
    if self.background == -1 { result.background = defaultAttributes.effectiveBackground }
    if self.special == -1 { result.special = defaultAttributes.special }

    return result
  }
}
