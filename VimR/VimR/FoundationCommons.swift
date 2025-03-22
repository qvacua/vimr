/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

extension Logger {
  // Logger's methods requires any object string-interpolated to be CustomStringConvertible.
  // I'm too lazy to make all Action's (enum's) CustomStringConvertible.
  func debugAny(_ msg: String) {
    #if DEBUG
//      self.debug("\(msg)")
    #endif
  }
}

extension URL {
  var direntType: Int16 {
    if self.isRegularFile { return Int16(DT_REG) }
    if self.hasDirectoryPath { return Int16(DT_DIR) }

    return Int16(DT_UNKNOWN)
  }
}
