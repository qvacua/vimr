/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView

class PrefUtils {
  static func value<T>(from dict: [String: Any], for key: String) -> T? {
    dict[key] as? T
  }

  static func value<T>(from dict: [String: Any], for key: String, default defaultValue: T) -> T {
    dict[key] as? T ?? defaultValue
  }

  static func dict(from dict: [String: Any], for key: String) -> [String: Any]? {
    dict[key] as? [String: Any]
  }

  static func float(from dict: [String: Any], for key: String,
                    default defaultValue: Float) -> Float
  {
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

  static func string(from dict: [String: Any], for key: String,
                     default defaultValue: String) -> String
  {
    dict[key] as? String ?? defaultValue
  }

  static func saneFont(_ fontName: String, fontSize: CGFloat) -> NSFont {
    var editorFont = NSFont(name: fontName, size: fontSize) ?? NvimView.defaultFont
    if !editorFont.isFixedPitch {
      editorFont = NSFontManager.shared.convert(NvimView.defaultFont, toSize: editorFont.pointSize)
    }
    if editorFont.pointSize < NvimView.minFontSize || editorFont.pointSize > NvimView.maxFontSize {
      editorFont = NSFontManager.shared.convert(editorFont, toSize: NvimView.defaultFont.pointSize)
    }

    return editorFont
  }

  static func saneLinespacing(_ fLinespacing: Float) -> CGFloat {
    let linespacing = fLinespacing.cgf
    guard linespacing >= NvimView.minLinespacing, linespacing <= NvimView.maxLinespacing else {
      return NvimView.defaultLinespacing
    }

    return linespacing
  }

  static func saneCharacterspacing(_ fCharacterspacing: Float) -> CGFloat {
    let characterspacing = fCharacterspacing.cgf
    guard characterspacing >= 0.0 else {
      return NvimView.defaultCharacterspacing
    }

    return characterspacing
  }
}
