/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView

enum PrefUtils {
  static func value<T>(from dict: [String: Any], for key: String) -> T? {
    dict[key] as? T
  }

  static func value<T>(from dict: [String: Any], for key: String, default defaultValue: T) -> T {
    dict[key] as? T ?? defaultValue
  }

  static func dict(from dict: [String: Any], for key: String) -> [String: Any]? {
    dict[key] as? [String: Any]
  }

  static func float(
    from dict: [String: Any],
    for key: String,
    default defaultValue: Float
  ) -> Float {
    (dict[key] as? NSNumber)?.floatValue ?? defaultValue
  }

  static func float(from dict: [String: Any], for key: String) -> Float? {
    guard let number = dict[key] as? NSNumber else {
      return nil
    }

    return number.floatValue
  }

  static func bool(from dict: [String: Any], for key: String) -> Bool? {
    guard let number = dict[key] as? NSNumber else {
      return nil
    }

    return number.boolValue
  }

  static func bool(from dict: [String: Any], for key: String, default defaultValue: Bool) -> Bool {
    (dict[key] as? NSNumber)?.boolValue ?? defaultValue
  }

  static func string(from dict: [String: Any], for key: String) -> String? {
    dict[key] as? String
  }

  static func string(
    from dict: [String: Any],
    for key: String,
    default defaultValue: String
  ) -> String {
    dict[key] as? String ?? defaultValue
  }
}
