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

extension Position {

  public static let beginning = Position(row: 1, column: 1)
}
