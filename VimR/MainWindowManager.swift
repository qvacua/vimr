/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class MainWindowManager {

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private var mainWindowComponents = [String:MainWindowComponent]()

  private var data: PrefData

  init(source: Observable<Any>, initialData: PrefData) {
    self.source = source
    self.data = initialData

    self.addReactions()
  }

  func newMainWindow(url: NSURL? = nil) -> MainWindowComponent {
    let mainWindowComponent = MainWindowComponent(source: self.source, manager: self, url: url, initialData: self.data)
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent
    return mainWindowComponent
  }
  
  func closeMainWindow(mainWindowComponent: MainWindowComponent) {
    self.mainWindowComponents.removeValueForKey(mainWindowComponent.uuid)
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }

  private func addReactions() {
    self.source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribeNext { [unowned self] prefData in
        self.data = prefData
      }
      .addDisposableTo(self.disposeBag)
  }
}
