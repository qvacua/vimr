/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

// The definition can be found in NeoVimUiBridgeProtocol.h

func == (left: CellAttributes, right: CellAttributes) -> Bool {
  if left.foreground != right.foreground { return false }
  if left.fontTrait != right.fontTrait { return false }
  
  if left.background != right.background { return false }
  if left.special != right.special { return false }
  
  return true
}

func != (left: CellAttributes, right: CellAttributes) -> Bool {
  return !(left == right)
}

extension CellAttributes: CustomStringConvertible {
  
  public var description: String {
    return "CellAttributes<fg: \(String(format: "%x", self.foreground)), bg: \(String(format: "%x", self.background)))"
  }
}

