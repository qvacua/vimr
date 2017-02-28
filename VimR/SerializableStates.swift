/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

fileprivate class Keys {

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
  }

  class WorkspaceTool {

    static let key = "workspace-tool"

    static let location = "location"
    static let open = "is-visible"
    static let dimension = "dimension"
  }
}

protocol SerializableState {

  func dict() -> [String: Any]
}

extension AppState: SerializableState {

  func dict() -> [String: Any] {
    return [
      Keys.openNewOnLaunch: self.openNewMainWindowOnLaunch,
      Keys.openNewOnReactivation: self.openNewMainWindowOnReactivation,
      Keys.useSnapshotUpdateChannel: self.useSnapshotUpdate,

      Keys.OpenQuickly.key: self.openQuickly.dict(),
    ]
  }
}

extension OpenQuicklyWindow.State: SerializableState {

  func dict() -> [String: Any] {
    return [
      Keys.OpenQuickly.ignorePatterns: FileItemIgnorePattern.toString(self.ignorePatterns)
    ]
  }
}

extension AppearanceState: SerializableState {

  func dict() -> [String: Any] {
    return [
      Keys.Appearance.editorFontName: self.font.fontName,
      Keys.Appearance.editorFontSize: Float(self.font.pointSize),
      Keys.Appearance.editorLinespacing: Float(self.linespacing),
      Keys.Appearance.editorUsesLigatures: self.usesLigatures,
    ]
  }
}

extension WorkspaceToolState: SerializableState {

  func dict() -> [String: Any] {
    return [
      Keys.WorkspaceTool.location: PrefUtils.locationAsString(for: self.location),
      Keys.WorkspaceTool.open: self.open,
      Keys.WorkspaceTool.dimension: Float(self.dimension),
    ]
  }
}

extension MainWindow.State: SerializableState {

  func dict() -> [String: Any] {
    return [
      Keys.MainWindow.allToolsVisible: self.isAllToolsVisible,
      Keys.MainWindow.toolButtonsVisible: self.isToolButtonsVisible,

      Keys.Appearance.key: self.appearance.dict(),
      Keys.WorkspaceTool.key: Array(self.tools.keys).toDict { self.tools[$0]!.dict() }
    ]
  }
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
