/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

private class PrefKeys {

  static let openNewWindowWhenLaunching = "open-new-window-when-launching"
  static let openNewWindowOnReactivation = "open-new-window-on-reactivation"
  static let openQuicklyIgnorePatterns = "open-quickly-ignore-patterns"

  static let editorFontName = "editor-font-name"
  static let editorFontSize = "editor-font-size"
  static let editorUsesLigatures = "editor-uses-ligatures"

  static let useInteractiveZsh = "use-interactive-zsh"
}

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
    advanced: AdvancedPrefData(useInteractiveZsh: false)
  )

  override init(source: Observable<Any>) {
    super.init(source: source)

    if let prefs = self.userDefaults.dictionary(forKey: PrefStore.compatibleVersion) {
      self.data = self.prefDataFromDict(prefs)
    } else {
      self.userDefaults.setValue(self.prefsDict(self.data), forKey: PrefStore.compatibleVersion)
    }
  }

  fileprivate func prefDataFromDict(_ prefs: [String: Any]) -> PrefData {

    let editorFontName = prefs[PrefKeys.editorFontName] as? String ?? PrefStore.defaultEditorFont.fontName
    let editorFontSize = CGFloat(
      (prefs[PrefKeys.editorFontSize] as? NSNumber)?.floatValue ?? Float(PrefStore.defaultEditorFont.pointSize)
    )
    let editorFont = self.saneFont(editorFontName, fontSize: editorFontSize)
    
    let usesLigatures = (prefs[PrefKeys.editorUsesLigatures] as? NSNumber)?.boolValue ?? false
    let openNewWindowWhenLaunching = (prefs[PrefKeys.openNewWindowWhenLaunching] as? NSNumber)?.boolValue ?? true
    let openNewWindowOnReactivation = (prefs[PrefKeys.openNewWindowOnReactivation] as? NSNumber)?.boolValue ?? true

    let ignorePatternsList = (prefs[PrefKeys.openQuicklyIgnorePatterns] as? String) ?? "*/.git, *.o, *.d, *.dia"
    let ignorePatterns = PrefUtils.ignorePatterns(fromString: ignorePatternsList)

    let useInteractiveZsh = (prefs[PrefKeys.useInteractiveZsh] as? NSNumber)?.boolValue ?? false

    return PrefData(
      general: GeneralPrefData(
        openNewWindowWhenLaunching: openNewWindowWhenLaunching,
        openNewWindowOnReactivation: openNewWindowOnReactivation,
        ignorePatterns: ignorePatterns
      ),
      appearance: AppearancePrefData(editorFont: editorFont, editorUsesLigatures: usesLigatures),
      advanced: AdvancedPrefData(useInteractiveZsh: useInteractiveZsh)
    )
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

  fileprivate func prefsDict(_ prefData: PrefData) -> [String: AnyObject] {
    let generalData = prefData.general
    let appearanceData = prefData.appearance
    let advancedData = prefData.advanced

    let prefs: [String: AnyObject] = [
      // General
      PrefKeys.openNewWindowWhenLaunching: generalData.openNewWindowWhenLaunching as AnyObject,
      PrefKeys.openNewWindowOnReactivation: generalData.openNewWindowOnReactivation as AnyObject,
      PrefKeys.openQuicklyIgnorePatterns: PrefUtils.ignorePatternString(fromSet: generalData.ignorePatterns) as AnyObject,

      // Appearance
      PrefKeys.editorFontName: appearanceData.editorFont.fontName as AnyObject,
      PrefKeys.editorFontSize: appearanceData.editorFont.pointSize as AnyObject,
      PrefKeys.editorUsesLigatures: appearanceData.editorUsesLigatures as AnyObject,

      // Advanced
      PrefKeys.useInteractiveZsh: advancedData.useInteractiveZsh as AnyObject,
    ]

    return prefs
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribe(onNext: { [unowned self] prefData in
        self.data = prefData
        self.userDefaults.setValue(self.prefsDict(prefData), forKey: PrefStore.compatibleVersion)
        self.publish(event: prefData)
      })
  }
}
