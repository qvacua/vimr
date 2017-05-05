/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

protocol SerializableState {

  init?(dict: [String: Any])

  func dict() -> [String: Any]
}

class PrefUtils {

  fileprivate static let whitespaceCharSet = CharacterSet.whitespaces

  static func ignorePatterns(fromString str: String) -> Set<FileItemIgnorePattern> {
    if str.trimmingCharacters(in: self.whitespaceCharSet).characters.count == 0 {
      return Set()
    }

    let patterns: [FileItemIgnorePattern] = str
      .components(separatedBy: ",")
      .flatMap {
        let trimmed = $0.trimmingCharacters(in: self.whitespaceCharSet)
        if trimmed.characters.count == 0 {
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

  static func saneFont(_ fontName: String, fontSize: CGFloat) -> NSFont {
    var editorFont = NSFont(name: fontName, size: fontSize) ?? NeoVimView.defaultFont
    if !editorFont.isFixedPitch {
      editorFont = NSFontManager.shared().convert(NeoVimView.defaultFont, toSize: editorFont.pointSize)
    }
    if editorFont.pointSize < NeoVimView.minFontSize || editorFont.pointSize > NeoVimView.maxFontSize {
      editorFont = NSFontManager.shared().convert(editorFont, toSize: NeoVimView.defaultFont.pointSize)
    }

    return editorFont
  }

  static func saneLinespacing(_ fLinespacing: Float) -> CGFloat {
    let linespacing = CGFloat(fLinespacing)
    guard linespacing >= NeoVimView.minLinespacing && linespacing <= NeoVimView.maxLinespacing else {
      return NeoVimView.defaultLinespacing
    }

    return linespacing
  }

  static func location(from strValue: String) -> WorkspaceBarLocation? {
    switch strValue {
    case "top": return .top
    case "right": return .right
    case "bottom": return .bottom
    case "left": return .left
    default: return nil
    }
  }

  static func locationAsString(for loc: WorkspaceBarLocation) -> String {
    switch loc {
    case .top: return "top"
    case .right: return "right"
    case .bottom: return "bottom"
    case .left: return "left"
    }
  }
}

class Keys {

  static let openNewOnLaunch = "open-new-window-when-launching"
  static let openNewOnReactivation = "open-new-window-on-reactivation"
  static let useSnapshotUpdateChannel = "use-snapshot-update-channel"

  class OpenQuickly {

    static let key = "open-quickly"

    static let ignorePatterns = "ignore-patterns"
  }

  class Appearance {

    static let key = "appearance"

    static let editorFontName = "editor-font-name"
    static let editorFontSize = "editor-font-size"
    static let editorLinespacing = "editor-linespacing"
    static let editorUsesLigatures = "editor-uses-ligatures"
  }

  class MainWindow {

    static let key = "main-window"

    static let allToolsVisible = "is-all-tools-visible"
    static let toolButtonsVisible = "is-tool-buttons-visible"
    static let orderedTools = "ordered-tools"

    static let useInteractiveZsh = "use-interactive-zsh"
    static let isShowHidden = "is-show-hidden"
  }

  class PreviewTool {

    static let key = "preview-tool"

    static let forwardSearchAutomatically = "is-forward-search-automatically"
    static let reverseSearchAutomatically = "is-reverse-search-automatically"
    static let refreshOnWrite = "is-refresh-on-write"
  }

  class WorkspaceTool {

    static let key = "workspace-tool"

    static let location = "location"
    static let open = "is-visible"
    static let dimension = "dimension"
  }
}
