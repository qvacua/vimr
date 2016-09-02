/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum MainWindowEvent {
  case allWindowsClosed
}

class MainWindowService: StandardFlow {
  
  static private let userHomeUrl = NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

  private var mainWindowComponents = [String:MainWindowComponent]()
  private weak var keyMainWindow: MainWindowComponent?

  private var data: PrefData

  init(source: Observable<Any>, initialData: PrefData) {
    self.data = initialData

    super.init(source: source)
  }

  func newMainWindow(urls urls: [NSURL] = [], cwd: NSURL = MainWindowService.userHomeUrl) -> MainWindowComponent {
    let mainWindowComponent = MainWindowComponent(
      source: self.source, urls: urls, initialData: self.data
    )
    mainWindowComponent.cwd = cwd
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent

    mainWindowComponent.sink
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribeNext { [unowned self] action in
        switch action {
        case let .becomeKey(mainWindow):
          self.setKeyWindow(mainWindow)
        case .openQuickly:
          self.publish(event: action)
        case let .close(mainWindow):
          self.closeMainWindow(mainWindow)
        }
      }
      .addDisposableTo(self.disposeBag)
    
    return mainWindowComponent
  }
  
  func closeMainWindow(mainWindowComponent: MainWindowComponent) {
    if self.keyMainWindow === mainWindowComponent {
      self.keyMainWindow = nil
    }
    
    self.mainWindowComponents.removeValueForKey(mainWindowComponent.uuid)

    if self.mainWindowComponents.isEmpty {
      self.publish(event: MainWindowEvent.allWindowsClosed)
    }
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
  
  func openInKeyMainWindow(urls urls:[NSURL] = [], cwd: NSURL = MainWindowService.userHomeUrl) {
    guard !self.mainWindowComponents.isEmpty else {
      self.newMainWindow(urls: urls, cwd: cwd)
      return
    }
    
    guard let keyMainWindow = self.keyMainWindow else {
      self.newMainWindow(urls: urls, cwd: cwd)
      return
    }
    
    keyMainWindow.cwd = cwd
    keyMainWindow.open(urls: urls)
  }
  
  func setKeyWindow(mainWindow: MainWindowComponent?) {
    self.keyMainWindow = mainWindow
  }
  
  func closeAllWindowsWithoutSaving() {
    self.mainWindowComponents.values.forEach { $0.closeAllNeoVimWindowsWithoutSaving() }
  }

  /// Assumes that no window is dirty.
  func closeAllWindows() {
    self.mainWindowComponents.values.forEach { $0.closeAllNeoVimWindows() }
  }

  func hasMainWindow() -> Bool {
    return !self.mainWindowComponents.isEmpty
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribeNext { [unowned self] prefData in
        self.data = prefData
    }
  }
}
