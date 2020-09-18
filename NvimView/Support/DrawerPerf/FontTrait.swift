/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public struct FontTrait: OptionSet {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

  static let italic = FontTrait(rawValue: 1 << 0)
  static let bold = FontTrait(rawValue: 1 << 1)
  static let underline = FontTrait(rawValue: 1 << 2)
  static let undercurl = FontTrait(rawValue: 1 << 3)
}
