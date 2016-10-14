/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import Sparkle

struct PrefData {
  var general: GeneralPrefData
  var appearance: AppearancePrefData
  var advanced: AdvancedPrefData

  var mainWindow: MainWindowPrefData
}

private class PrefKeys {

  static let openNewWindowWhenLaunching = "open-new-window-when-launching"
  static let openNewWindowOnReactivation = "open-new-window-on-reactivation"
  static let openQuicklyIgnorePatterns = "open-quickly-ignore-patterns"

  static let editorFontName = "editor-font-name"
  static let editorFontSize = "editor-font-size"
  static let editorUsesLigatures = "editor-uses-ligatures"

  static let useSnapshotUpdateChannel = "use-snapshot-update-channel"
  static let useInteractiveZsh = "use-interactive-zsh"

  static let isAllToolsVisible = "is-all-tools-visible"
  static let isToolButtonsShown = "is-tool-buttons-visible"

  static let isFileBrowserOpen = "is-file-browser-visible"
  static let fileBrowserWidth = "file-browser-width"
}

// TODO: We should generalize the persisting of pref data.
class PrefStore: StandardFlow {

  fileprivate static let compatibleVersion = "38"
  fileprivate static let defaultEditorFont = NeoVimView.defaultFont
  static let minimumEditorFontSize = NeoVimView.minFontSize
  static let maximumEditorFontSize = NeoVimView.maxFontSize

  fileprivate let userDefaults = UserDefaults.standard
  fileprivate let fontManager = NSFontManager.shared()

  var data = PrefData(
    general: GeneralPrefData(openNewWindowWhenLaunching: true,
                             openNewWindowOnReactivation: true,
                             ignorePatterns: Set([ "*/.git", "*.o", "*.d", "*.dia" ].map(FileItemIgnorePattern.init))),
    appearance: AppearancePrefData(editorFont: PrefStore.defaultEditorFont, editorUsesLigatures: false),
    advanced: AdvancedPrefData(useSnapshotUpdateChannel: false,
                               useInteractiveZsh: false),
    mainWindow: MainWindowPrefData(isAllToolsVisible: true,
                                   isToolButtonsVisible: true,
                                   isFileBrowserVisible: true,
                                   fileBrowserWidth: 200)
  )

  override init(source: Observable<Any>) {
    super.init(source: source)

    if let prefs = self.userDefaults.dictionary(forKey: PrefStore.compatibleVersion) {
      self.data = self.prefDataFromDict(prefs)
    } else {
      self.userDefaults.setValue(self.prefsDict(self.data), forKey: PrefStore.compatibleVersion)
    }

    if self.data.advanced.useSnapshotUpdateChannel {
      SUUpdater.shared().feedURL = URL(
        string: "https://raw.githubusercontent.com/qvacua/vimr/master/appcast_snapshot.xml"
      )
    }
  }

  fileprivate func prefDataFromDict(_ prefs: [String: Any]) -> PrefData {

    let editorFontName = prefs[PrefKeys.editorFontName] as? String ?? PrefStore.defaultEditorFont.fontName
    let editorFontSize = CGFloat(
      (prefs[PrefKeys.editorFontSize] as? NSNumber)?.floatValue ?? Float(PrefStore.defaultEditorFont.pointSize)
    )
    let editorFont = self.saneFont(editorFontName, fontSize: editorFontSize)

    let usesLigatures = self.bool(from: prefs, for: PrefKeys.editorUsesLigatures, default: false)
    let openNewWindowWhenLaunching = self.bool(from: prefs, for: PrefKeys.openNewWindowWhenLaunching, default: true)
    let openNewWindowOnReactivation = self.bool(from: prefs, for: PrefKeys.openNewWindowOnReactivation, default: true)

    let ignorePatternsList = (prefs[PrefKeys.openQuicklyIgnorePatterns] as? String) ?? "*/.git, *.o, *.d, *.dia"
    let ignorePatterns = PrefUtils.ignorePatterns(fromString: ignorePatternsList)

    let useSnapshotUpdate = self.bool(from: prefs, for: PrefKeys.useSnapshotUpdateChannel, default: false)
    let useInteractiveZsh = self.bool(from: prefs, for: PrefKeys.useInteractiveZsh, default: false)

    let isAllToolsVisible = self.bool(from: prefs, for: PrefKeys.isAllToolsVisible, default: true)
    let isToolButtonsVisible = self.bool(from: prefs, for: PrefKeys.isToolButtonsShown, default: true)
    let isFileBrowserVisible = self.bool(from: prefs, for: PrefKeys.isFileBrowserOpen, default: true)
    let fileBrowserWidth = (prefs[PrefKeys.fileBrowserWidth] as? NSNumber)?.floatValue ?? Float(200)

    return PrefData(
      general: GeneralPrefData(
        openNewWindowWhenLaunching: openNewWindowWhenLaunching,
        openNewWindowOnReactivation: openNewWindowOnReactivation,
        ignorePatterns: ignorePatterns
      ),
      appearance: AppearancePrefData(editorFont: editorFont, editorUsesLigatures: usesLigatures),
      advanced: AdvancedPrefData(useSnapshotUpdateChannel: useSnapshotUpdate,
                                 useInteractiveZsh: useInteractiveZsh),
      mainWindow: MainWindowPrefData(isAllToolsVisible: isAllToolsVisible,
                                     isToolButtonsVisible: isToolButtonsVisible,
                                     isFileBrowserVisible: isFileBrowserVisible,
                                     fileBrowserWidth: fileBrowserWidth)
    )
  }

  fileprivate func bool(from prefs: [String: Any], for key: String, default defaultValue: Bool) -> Bool {
    return (prefs[key] as? NSNumber)?.boolValue ?? defaultValue
  }

  fileprivate func saneFont(_ fontName: String, fontSize: CGFloat) -> NSFont {
    var editorFont = NSFont(name: fontName, size: fontSize) ?? PrefStore.defaultEditorFont
    if !editorFont.isFixedPitch {
      editorFont = fontManager.convert(PrefStore.defaultEditorFont, toSize: editorFont.pointSize)
    }
    if editorFont.pointSize < PrefStore.minimumEditorFontSize
      || editorFont.pointSize > PrefStore.maximumEditorFontSize {
      editorFont = fontManager.convert(editorFont, toSize: PrefStore.defaultEditorFont.pointSize)
    }

    return editorFont
  }

  fileprivate func prefsDict(_ prefData: PrefData) -> [String: Any] {
    let generalData = prefData.general
    let appearanceData = prefData.appearance
    let advancedData = prefData.advanced
    let mainWindowData = prefData.mainWindow

    let ignorePatterns = PrefUtils.ignorePatternString(fromSet: generalData.ignorePatterns) as Any

    let prefs: [String: Any] = [
      // General
      PrefKeys.openNewWindowWhenLaunching: generalData.openNewWindowWhenLaunching as Any,
      PrefKeys.openNewWindowOnReactivation: generalData.openNewWindowOnReactivation as Any,
      PrefKeys.openQuicklyIgnorePatterns: ignorePatterns,

      // Appearance
      PrefKeys.editorFontName: appearanceData.editorFont.fontName as Any,
      PrefKeys.editorFontSize: appearanceData.editorFont.pointSize as Any,
      PrefKeys.editorUsesLigatures: appearanceData.editorUsesLigatures as Any,

      // Advanced
      PrefKeys.useSnapshotUpdateChannel: advancedData.useSnapshotUpdateChannel as Any,
      PrefKeys.useInteractiveZsh: advancedData.useInteractiveZsh as Any,

      // MainWindow
      PrefKeys.isAllToolsVisible: mainWindowData.isAllToolsVisible,
      PrefKeys.isToolButtonsShown: mainWindowData.isToolButtonsVisible,
      PrefKeys.isFileBrowserOpen: mainWindowData.isFileBrowserVisible,
      PrefKeys.fileBrowserWidth: mainWindowData.fileBrowserWidth
    ]

    return prefs
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData || $0 is MainWindowPrefData }
      .subscribe(onNext: { [unowned self] data in
        switch data {
        case let prefData as PrefData:
          self.data = prefData

        case let mainWindowPrefData as MainWindowPrefData:
          self.data.mainWindow = mainWindowPrefData

        default:
          return
        }

        self.userDefaults.setValue(self.prefsDict(self.data), forKey: PrefStore.compatibleVersion)
        self.publish(event: self.data)
        })
  }
}
