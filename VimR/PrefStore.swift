/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

private class PrefKeys {

  static let editorFontName = "editor-font-name"
  static let editorFontSize = "editor-font-size"
}

class PrefStore: Store {

  private static let compatibleVersion = "38"
  private static let defaultEditorFont = NSFont(name: "Menlo", size: 13)!
  private static let minimumEditorFontSize = CGFloat(4)
  private static let maximumEditorFontSize = CGFloat(128)

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  private let userDefaults = NSUserDefaults.standardUserDefaults()
  private let fontManager = NSFontManager.sharedFontManager()

  var data = PrefData(appearance: AppearancePrefData(editorFont: PrefStore.defaultEditorFont))

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

    return PrefData(appearance: AppearancePrefData(editorFont: editorFont))
  }

  private func prefsDict(prefData: PrefData) -> [String: AnyObject] {
    let appearanceData = prefData.appearance
    let prefs: [String: AnyObject] = [
        PrefKeys.editorFontName: appearanceData.editorFont.fontName,
        PrefKeys.editorFontSize: appearanceData.editorFont.pointSize
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
