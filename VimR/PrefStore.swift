/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

private class PrefKeys {

  static let editorFontName = "editor-font-name"
  static let editorFontSize = "editor-font-size"
  static let editorUsesLigatures = "editor-uses-ligatures"
}

class PrefStore: Store {

  private static let compatibleVersion = "38"
  private static let defaultEditorFont = NeoVimView.defaultFont
  static let minimumEditorFontSize = NeoVimView.minFontSize
  static let maximumEditorFontSize = NeoVimView.maxFontSize

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  private let userDefaults = NSUserDefaults.standardUserDefaults()
  private let fontManager = NSFontManager.sharedFontManager()

  var data = PrefData(appearance: AppearancePrefData(editorFont: PrefStore.defaultEditorFont,
                                                     editorUsesLigatures: false))

  init(source: Observable<Any>) {
    self.source = source

    if let prefs = self.userDefaults.dictionaryForKey(PrefStore.compatibleVersion) {
      self.data = self.prefDataFromDict(prefs)
    } else {
      self.userDefaults.setValue(self.prefsDict(self.data), forKey: PrefStore.compatibleVersion)
    }

    self.addReactions()
  }

  deinit {
    self.subject.onCompleted()
  }

  private func prefDataFromDict(prefs: [String: AnyObject]) -> PrefData {
    let defaultFontSize = NSNumber(float: Float(PrefStore.defaultEditorFont.pointSize))

    let editorFontName = prefs[PrefKeys.editorFontName] as? String ?? PrefStore.defaultEditorFont.fontName
    let editorFontSizeFromPref = prefs[PrefKeys.editorFontSize] as? NSNumber ?? defaultFontSize
    let editorFontSize: CGFloat = CGFloat(editorFontSizeFromPref.floatValue) ?? CGFloat(defaultFontSize)

    var editorFont = NSFont(name: editorFontName, size: editorFontSize) ?? PrefStore.defaultEditorFont
    if !editorFont.fixedPitch {
      editorFont = fontManager.convertFont(PrefStore.defaultEditorFont, toSize: editorFont.pointSize)
    }
    if editorFont.pointSize < PrefStore.minimumEditorFontSize
      || editorFont.pointSize > PrefStore.maximumEditorFontSize {
      editorFont = fontManager.convertFont(editorFont, toSize: CGFloat(defaultFontSize))
    }
    
    let usesLigatures: Bool
    if let usesLigaturesFromPref = prefs[PrefKeys.editorUsesLigatures] as? NSNumber {
      usesLigatures = usesLigaturesFromPref.boolValue
    } else {
      usesLigatures = false
    }

    return PrefData(appearance: AppearancePrefData(editorFont: editorFont, editorUsesLigatures: usesLigatures))
  }

  private func prefsDict(prefData: PrefData) -> [String: AnyObject] {
    let appearanceData = prefData.appearance
    let prefs: [String: AnyObject] = [
      PrefKeys.editorFontName: appearanceData.editorFont.fontName,
      PrefKeys.editorFontSize: appearanceData.editorFont.pointSize,
      PrefKeys.editorUsesLigatures: appearanceData.editorUsesLigatures
    ]
    return prefs
  }

  private func addReactions() {
    self.source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribeNext { [unowned self] prefData in
        self.data = prefData
        self.userDefaults.setValue(self.prefsDict(prefData), forKey: PrefStore.compatibleVersion)
        self.subject.onNext(prefData)
      }
      .addDisposableTo(self.disposeBag)
  }
}
