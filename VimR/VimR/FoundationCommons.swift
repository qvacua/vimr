/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

extension URL {
  var direntType: Int16 {
    if self.isRegularFile { return Int16(DT_REG)}
    if self.hasDirectoryPath { return Int16(DT_DIR) }

    return Int16(DT_UNKNOWN)
  }
}
