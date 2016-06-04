/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class NeoVimUiImpl : NSObject, NeoVimUi {

  func modeChange(mode: Int32) {
    print("### mode change to: \(String(format:"%04X", mode))")
  }

  func put(str: String) {
    print("### " + str);
  }
}
