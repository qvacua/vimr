/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

protocol StandardPrefData {

  init?(dict: [String: Any])
  func dict() -> [String: Any]
}

struct EmptyPrefData: StandardPrefData {

  static let `default` = EmptyPrefData()

  init() {}

  init?(dict: [String: Any]) {
    self.init()
  }

  func dict() -> [String: Any] {
    return [:]
  }
}

struct PrefData: StandardPrefData {

  fileprivate static let general = "general"
  fileprivate static let appearance = "appearance"
  fileprivate static let advanced = "advanced"
  fileprivate static let mainWindow = "mainWindow"

  static let `default` = PrefData(general: .default, appearance: .default, advanced: .default, mainWindow: .default)

  var general: GeneralPrefData
  var appearance: AppearancePrefData
  var advanced: AdvancedPrefData

  var mainWindow: MainWindowPrefData

  init(general: GeneralPrefData,
       appearance: AppearancePrefData,
       advanced: AdvancedPrefData,
       mainWindow: MainWindowPrefData)
  {
    self.general = general
    self.appearance = appearance
    self.advanced = advanced
    self.mainWindow = mainWindow
  }

  init?(dict: [String: Any]) {
    guard let generalDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.general),
          let appearanceDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.appearance),
          let advancedDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.advanced),
          let mainWindowDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.mainWindow)
        else {
      return nil
    }

    guard let general = GeneralPrefData(dict: generalDict),
          let appearance = AppearancePrefData(dict: appearanceDict),
          let advanced = AdvancedPrefData(dict: advancedDict),
          let mainWindow = MainWindowPrefData(dict: mainWindowDict)
        else {
      return nil
    }

    self.init(general: general, appearance: appearance, advanced: advanced, mainWindow: mainWindow)
  }

  func dict() -> [String: Any] {
    return [
        PrefData.general: self.general.dict(),
        PrefData.appearance: self.appearance.dict(),
        PrefData.advanced: self.advanced.dict(),
        PrefData.mainWindow: self.mainWindow.dict(),
    ]
  }
}

/**
 To reset prefs for 38
 $ defaults write com.qvacua.vimr 38 -dict editor-font-name InputMonoCompressed-Regular editor-font-size 13 editor-uses-ligatures 0 open-new-window-on-reactivation 1 open-new-window-when-launching 1
 $ defaults read ~/Library/Preferences/com.qvacua.VimR
 */
class PrefStore: StandardFlow {

  fileprivate static let compatibleVersion = "128"
  fileprivate static let lastCompatibleVersion = "38"

  fileprivate let userDefaults = UserDefaults.standard

  var data = PrefData.default

  override init(source: Observable<Any>) {
    super.init(source: source)

    if let prefs = self.userDefaults.dictionary(forKey: PrefStore.compatibleVersion) {
      // 128
      self.data = PrefData(dict: prefs) ?? .default
    } else if let dictLastVersion = self.userDefaults.dictionary(forKey: PrefStore.lastCompatibleVersion) {
      // 38
      self.data = Pref38To128Converter().prefData128(from: dictLastVersion)
    }

    // We write self.data here for when PrefData(dict: prefs) was nil or the prefs last compatible version was
    // converted.
    self.userDefaults.setValue(self.data.dict(), forKey: PrefStore.compatibleVersion)
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

        self.userDefaults.setValue(self.data.dict(), forKey: PrefStore.compatibleVersion)
        self.publish(event: self.data)
        })
  }
}
