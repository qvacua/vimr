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
    let output = self.vimOutput(of: "echo line('.')")
    return Int(output) ?? 0
  }


  func currentColumn() -> Int {
    let output = self.vimOutput(of: "echo virtcol('.')")
    return Int(output) ?? 0
  }
}
