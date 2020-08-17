/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class KeyUtils {

  static func isControlCode(key: String) -> Bool {
    guard key.count == 1 else {
      return false
    }

    guard let firstChar = key.utf16.first else {
      return false
    }

    return firstChar < 32 && firstChar > 0
  }

  static func isSpecial(key: String) -> Bool {
    guard key.count == 1 else {
      return false
    }

    if let firstChar = key.utf16.first {
      return specialKeys.keys.contains(Int(firstChar))
    }

    return false
  }

  static func namedKey(from key: String) -> String {
    if let firstChar = key.utf16.first, let special = specialKeys[Int(firstChar)] {
      return special
    }

    return key
  }
}

private let specialKeys = [
  NSUpArrowFunctionKey: "Up",
  NSDownArrowFunctionKey: "Down",
  NSLeftArrowFunctionKey: "Left",
  NSRightArrowFunctionKey: "Right",
  NSInsertFunctionKey: "Insert",
  0x7F: "BS", // "delete"-key
  NSDeleteFunctionKey: "Del", // "Fn+delete"-key
  NSHomeFunctionKey: "Home",
  NSBeginFunctionKey: "Begin",
  NSEndFunctionKey: "End",
  NSPageUpFunctionKey: "PageUp",
  NSPageDownFunctionKey: "PageDown",
  NSHelpFunctionKey: "Help",
  NSF1FunctionKey: "F1",
  NSF2FunctionKey: "F2",
  NSF3FunctionKey: "F3",
  NSF4FunctionKey: "F4",
  NSF5FunctionKey: "F5",
  NSF6FunctionKey: "F6",
  NSF7FunctionKey: "F7",
  NSF8FunctionKey: "F8",
  NSF9FunctionKey: "F9",
  NSF10FunctionKey: "F10",
  NSF11FunctionKey: "F11",
  NSF12FunctionKey: "F12",
  NSF13FunctionKey: "F13",
  NSF14FunctionKey: "F14",
  NSF15FunctionKey: "F15",
  NSF16FunctionKey: "F16",
  NSF17FunctionKey: "F17",
  NSF18FunctionKey: "F18",
  NSF19FunctionKey: "F19",
  NSF20FunctionKey: "F20",
  NSF21FunctionKey: "F21",
  NSF22FunctionKey: "F22",
  NSF23FunctionKey: "F23",
  NSF24FunctionKey: "F24",
  NSF25FunctionKey: "F25",
  NSF26FunctionKey: "F26",
  NSF27FunctionKey: "F27",
  NSF28FunctionKey: "F28",
  NSF29FunctionKey: "F29",
  NSF30FunctionKey: "F30",
  NSF31FunctionKey: "F31",
  NSF32FunctionKey: "F32",
  NSF33FunctionKey: "F33",
  NSF34FunctionKey: "F34",
  NSF35FunctionKey: "F35",
  0x09: "Tab",
  0x19: "Tab",
  0xd: "CR",
  0x20: "Space",
]
