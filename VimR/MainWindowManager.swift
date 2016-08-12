/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum MainWindowEvent {
  case allWindowsClosed
}

class MainWindowManager {

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }
  
  private var mainWindowComponents = [String:MainWindowComponent]()

  private var data: PrefData

  init(source: Observable<Any>, initialData: PrefData) {
    self.source = source
    self.data = initialData

    self.addReactions()
  }

  func newMainWindow(urls urls: [NSURL] = []) -> MainWindowComponent {
    let mainWindowComponent = MainWindowComponent(source: self.source,
                                                  manager: self,
                                                  urls: urls,
                                                  initialData: self.data)
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent
    return mainWindowComponent
  }
  
  func closeMainWindow(mainWindowComponent: MainWindowComponent) {
    self.mainWindowComponents.removeValueForKey(mainWindowComponent.uuid)
    
    if self.mainWindowComponents.isEmpty {
      NSLog("\(#function) all closed")
      self.subject.onNext(MainWindowEvent.allWindowsClosed)
    }
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
  
  func closeAllWindowsWithoutSaving() {
    self.mainWindowComponents.values.forEach { $0.closeAllNeoVimWindowsWithoutSaving() }
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
