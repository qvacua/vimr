/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum MainWindowEvent {
  case allWindowsClosed
}

class MainWindowManager: StandardFlow {
  
  static fileprivate let userHomeUrl = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

  fileprivate var mainWindowComponents = [String:MainWindowComponent]()
  fileprivate weak var keyMainWindow: MainWindowComponent?

  fileprivate let fileItemService: FileItemService
  fileprivate var data: PrefData

  init(source: Observable<Any>, fileItemService: FileItemService, initialData: PrefData) {
    self.fileItemService = fileItemService
    self.data = initialData

    super.init(source: source)
  }

  func newMainWindow(urls: [URL] = [], cwd: URL = MainWindowManager.userHomeUrl) -> MainWindowComponent {
    let mainWindowComponent = MainWindowComponent(
      source: self.source, fileItemService: self.fileItemService, cwd: cwd, urls: urls, initialData: self.data
    )
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent

    mainWindowComponent.sink
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .becomeKey(mainWindow):
          self.set(keyMainWindow: mainWindow)

        case .openQuickly:
          self.publish(event: action)

        case let .close(mainWindow):
          self.closeMainWindow(mainWindow)

        case .changeCwd:
          break
        }
      })
      .addDisposableTo(self.disposeBag)
    
    return mainWindowComponent
  }
  
  func closeMainWindow(_ mainWindowComponent: MainWindowComponent) {
    if self.keyMainWindow === mainWindowComponent {
      self.keyMainWindow = nil
    }
    
    self.mainWindowComponents.removeValue(forKey: mainWindowComponent.uuid)

    if self.mainWindowComponents.isEmpty {
      self.publish(event: MainWindowEvent.allWindowsClosed)
    }
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
  
  func openInKeyMainWindow(urls:[URL] = [], cwd: URL = MainWindowManager.userHomeUrl) {
    guard !self.mainWindowComponents.isEmpty else {
      _ = self.newMainWindow(urls: urls, cwd: cwd)
      return
    }
    
    guard let keyMainWindow = self.keyMainWindow else {
      _ = self.newMainWindow(urls: urls, cwd: cwd)
      return
    }
    
    keyMainWindow.cwd = cwd
    keyMainWindow.open(urls: urls)
  }
  
  fileprivate func set(keyMainWindow mainWindow: MainWindowComponent?) {
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

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribe(onNext: { [unowned self] prefData in
        self.data = prefData
    })
  }
}
