/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView

class PrefUtils {

  private static let whitespaceCharSet = CharacterSet.whitespaces

  static func ignorePatterns(fromString str: String) -> Set<FileItemIgnorePattern> {
    if str.trimmingCharacters(in: self.whitespaceCharSet).count == 0 {
      return Set()
    }

    let patterns: [FileItemIgnorePattern] = str
      .components(separatedBy: ",")
      .flatMap {
        let trimmed = $0.trimmingCharacters(in: self.whitespaceCharSet)
        if trimmed.count == 0 {
          return nil
        }

        return FileItemIgnorePattern(pattern: trimmed)
      }

    return Set(patterns)
  }

  static func ignorePatternString(fromSet set: Set<FileItemIgnorePattern>) -> String {
    return Array(set)
      .map { $0.pattern }
      .sorted()
      .joined(separator: ", ")
  }

  static func value<T>(from dict: [String: Any], for key: String) -> T? {
    return dict[key] as? T
  }

  static func value<T>(from dict: [String: Any], for key: String, default defaultValue: T) -> T {
    return dict[key] as? T ?? defaultValue
  }

  static func dict(from dict: [String: Any], for key: String) -> [String: Any]? {
    return dict[key] as? [String: Any]
  }

  static func float(from dict: [String: Any], for key: String, default defaultValue: Float) -> Float {
    return (dict[key] as? NSNumber)?.floatValue ?? defaultValue
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
    return (dict[key] as? NSNumber)?.boolValue ?? defaultValue
  }

  static func string(from dict: [String: Any], for key: String) -> String? {
    return dict[key] as? String
  }

  static func string(from dict: [String: Any], for key: String, default defaultValue: String) -> String {
    return dict[key] as? String ?? defaultValue
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
    let linespacing = CGFloat(fLinespacing)
    guard linespacing >= NvimView.minLinespacing && linespacing <= NvimView.maxLinespacing else {
      return NvimView.defaultLinespacing
    }

    return linespacing
  }
}
