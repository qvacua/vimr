/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum MainWindowManagerAction {

  case allWindowsClosed
}

class MainWindowManager: StandardFlow {

  fileprivate var mainWindowComponents = [String:MainWindowComponent]()
  fileprivate weak var keyMainWindow: MainWindowComponent?

  fileprivate let fileItemService: FileItemService
  fileprivate var data: PrefData

  init(source: Observable<Any>, fileItemService: FileItemService, initialData: PrefData) {
    self.fileItemService = fileItemService
    self.data = initialData

    super.init(source: source)
  }

  func newMainWindow(urls: [URL] = [], cwd: URL = FileUtils.userHomeUrl) -> MainWindowComponent {
    let mainWindowComponent = MainWindowComponent(source: self.source,
                                                  fileItemService: self.fileItemService,
                                                  cwd: cwd,
                                                  urls: urls,
                                                  initialData: self.data)

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

        case let .close(mainWindow, mainWindowPrefData):
          self.close(mainWindow, prefData: mainWindowPrefData)

        case .changeCwd:
          break
        }
      })
      .addDisposableTo(self.disposeBag)
    
    return mainWindowComponent
  }
  
  func close(_ mainWindowComponent: MainWindowComponent, prefData: MainWindowPrefData) {
    // Save the tools settings of the last closed main window.
    // TODO: Think about a better time to save this.
    self.publish(event: prefData)

    if self.keyMainWindow === mainWindowComponent {
      self.keyMainWindow = nil
    }
    
    self.mainWindowComponents.removeValue(forKey: mainWindowComponent.uuid)

    if self.mainWindowComponents.isEmpty {
      self.publish(event: MainWindowManagerAction.allWindowsClosed)
    }
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
  
  func openInKeyMainWindow(urls:[URL] = [], cwd: URL = FileUtils.userHomeUrl) {
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
