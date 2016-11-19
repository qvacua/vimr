/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

fileprivate class PrefKeys38 {
  
  static let openNewWindowWhenLaunching = "open-new-window-when-launching"
  static let openNewWindowOnReactivation = "open-new-window-on-reactivation"
  static let openQuicklyIgnorePatterns = "open-quickly-ignore-patterns"
  
  static let editorFontName = "editor-font-name"
  static let editorFontSize = "editor-font-size"
  static let editorLinespacing = "editor-linespacing"
  static let editorUsesLigatures = "editor-uses-ligatures"
  
  static let useSnapshotUpdateChannel = "use-snapshot-update-channel"
  static let useInteractiveZsh = "use-interactive-zsh"
  
  static let isAllToolsVisible = "is-all-tools-visible"
  static let isToolButtonsShown = "is-tool-buttons-visible"
  
  static let isFileBrowserOpen = "is-file-browser-visible"
  static let fileBrowserWidth = "file-browser-width"
}

class Pref38To128Converter {
  
  static let fromVersion = "38"
  static let toVersion = "128"

  fileprivate let userDefaults = UserDefaults.standard
  fileprivate let fontManager = NSFontManager.shared()
  
  func prefData128(from dict38: [String: Any]) -> PrefData {
    
    let editorFontName = dict38[PrefKeys38.editorFontName] as? String ?? NeoVimView.defaultFont.fontName

    let editorFontSize = CGFloat(
      PrefUtils.float(from: dict38, for: PrefKeys38.editorFontSize) ?? Float(NeoVimView.defaultFont.pointSize)
    )
    let editorFont = PrefUtils.saneFont(editorFontName, fontSize: editorFontSize)
    
    let usesLigatures = PrefUtils.bool(from: dict38, for: PrefKeys38.editorUsesLigatures, default: false)
    let linespacingAsStr = PrefUtils.value(from: dict38, for: PrefKeys38.editorLinespacing, default: "1")
    let linespacing = PrefUtils.saneLinespacing(Float(linespacingAsStr) ?? 1)
    let openNewWindowWhenLaunching = PrefUtils.bool(from: dict38,
                                                    for: PrefKeys38.openNewWindowWhenLaunching,
                                                    default: true)
    let openNewWindowOnReactivation = PrefUtils.bool(from: dict38,
                                                     for: PrefKeys38.openNewWindowOnReactivation,
                                                     default: true)
    
    let ignorePatternsList = (dict38[PrefKeys38.openQuicklyIgnorePatterns] as? String) ?? "*/.git, *.o, *.d, *.dia"
    let ignorePatterns = PrefUtils.ignorePatterns(fromString: ignorePatternsList)
    
    let useSnapshotUpdate = PrefUtils.bool(from: dict38, for: PrefKeys38.useSnapshotUpdateChannel, default: false)
    let useInteractiveZsh = PrefUtils.bool(from: dict38, for: PrefKeys38.useInteractiveZsh, default: false)
    
    let isAllToolsVisible = PrefUtils.bool(from: dict38, for: PrefKeys38.isAllToolsVisible, default: true)
    let isToolButtonsVisible = PrefUtils.bool(from: dict38, for: PrefKeys38.isToolButtonsShown, default: true)
    let isFileBrowserVisible = PrefUtils.bool(from: dict38, for: PrefKeys38.isFileBrowserOpen, default: true)
    let fileBrowserWidth = PrefUtils.float(from: dict38, for: PrefKeys38.fileBrowserWidth, default: 200)

    let fileBrowserData = ToolPrefData(identifier: .fileBrowser,
                                       location: .left,
                                       isVisible: isFileBrowserVisible,
                                       dimension: CGFloat(fileBrowserWidth))

    return PrefData(
      general: GeneralPrefData(
        openNewWindowWhenLaunching: openNewWindowWhenLaunching,
        openNewWindowOnReactivation: openNewWindowOnReactivation,
        ignorePatterns: ignorePatterns
      ),
      appearance: AppearancePrefData(editorFont: editorFont,
                                     editorLinespacing: linespacing,
                                     editorUsesLigatures: usesLigatures),
      advanced: AdvancedPrefData(useSnapshotUpdateChannel: useSnapshotUpdate,
                                 useInteractiveZsh: useInteractiveZsh),
      mainWindow: MainWindowPrefData(isAllToolsVisible: isAllToolsVisible,
                                     isToolButtonsVisible: isToolButtonsVisible,
                                     toolPrefDatas: [ fileBrowserData ])
    )
  }
}
