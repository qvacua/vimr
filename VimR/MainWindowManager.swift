/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class MainWindowManager {

  private let source: Observable<Any>
  private var mainWindowComponents = [String:MainWindowComponent]()

  init(source: Observable<Any>) {
    self.source = source
  }

  func newMainWindow() {
   let mainWindowComponent = MainWindowComponent(source: self.source, manager: self)
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent
  }
  
  func closeMainWindow(mainWindowComponent: MainWindowComponent) {
    self.mainWindowComponents.removeValueForKey(mainWindowComponent.uuid)
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
}
