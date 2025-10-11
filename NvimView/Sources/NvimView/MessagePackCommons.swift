/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import MessagePack

extension MessagePackValue {
  var intValue: Int? {
    guard let i64 = self.int64Value else { return nil }

    return Int(i64)
  }
}

enum MessagePackUtils {
  static func array<T>(
    from value: MessagePackValue, ofSize size: Int,
    conversion: (MessagePackValue) -> T?
  ) -> [T]? {
    guard let array = value.arrayValue else { return nil }
    guard array.count == size else { return nil }

    return array.compactMap(conversion)
  }
}
