/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class MainWindowManager {

  private let prefWindowComponent: PrefWindowComponent
  private var mainWindowComponents = [String:MainWindowComponent]()

  init(prefWindowComponent: PrefWindowComponent) {
    self.prefWindowComponent = prefWindowComponent
  }

  func newMainWindow() {
    let mainWindowComponent = MainWindowComponent(source: self.prefWindowComponent.sink, manager: self)
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent
  }
  
  func closeMainWindow(mainWindowComponent: MainWindowComponent) {
    self.mainWindowComponents.removeValueForKey(mainWindowComponent.uuid)
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
}
