/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation


extension NeoVimTab {

  public func allBuffers() -> [NeoVimBuffer] {
    return Array(Set(self.windows.map { $0.buffer }))
  }
}
