/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

// The definition can be found in NeoVimUiBridgeProtocol.h

extension CellAttributes: CustomStringConvertible, Equatable {

  public static func ==(left: CellAttributes, right: CellAttributes) -> Bool {
    if left.foreground != right.foreground { return false }
    if left.fontTrait != right.fontTrait { return false }

    if left.background != right.background { return false }
    if left.special != right.special { return false }

    return true
  }

  public var description: String {
    return "CellAttributes<fg: \(String(self.foreground, radix: 16)), " +
           "bg: \(String(self.background, radix: 16)))>"
  }

  public var inverted: CellAttributes {
    var result = self

    result.background = self.foreground
    result.foreground = self.background

    return result
  }
}
