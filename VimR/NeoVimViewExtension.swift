/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import SwiftNeoVim

protocol NeoVimInfoProvider: class {

  func currentLine() -> Int
  func currentColumn() -> Int
}

extension NeoVimView: NeoVimInfoProvider {

  func currentLine() -> Int {
    return self.currentPosition.row
  }


  func currentColumn() -> Int {
    return self.currentPosition.column
  }
}
