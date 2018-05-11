/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import MessagePack

extension MessagePackValue {

  var intValue: Int? {
    guard let i64 = self.integerValue else {
      return nil
    }

    return Int(i64)
  }
}
