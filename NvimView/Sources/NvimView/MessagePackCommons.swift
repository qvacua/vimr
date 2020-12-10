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
  static func value<T>(from data: Data?, conversion: (MessagePackValue) -> T?) -> T? {
    guard let d = data else { return nil }

    do { return conversion(try unpack(d).value) }
    catch { return nil }
  }

  static func value<T>(from v: MessagePackValue, conversion: (MessagePackValue) -> T?) -> T? {
    conversion(v)
  }

  static func array<T>(
    from value: MessagePackValue, ofSize size: Int,
    conversion: (MessagePackValue) -> T?
  ) -> [T]? {
    guard let array = value.arrayValue else { return nil }
    guard array.count == size else { return nil }

    return array.compactMap(conversion)
  }

  static func value(from data: Data?) -> MessagePackValue? {
    guard let d = data else { return nil }

    do { return try unpack(d).value }
    catch { return nil }
  }
}
