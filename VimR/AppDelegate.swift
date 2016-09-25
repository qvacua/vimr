/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

private let filePrefix = "file="
private let cwdPrefix = "cwd="

/// Keep the rawValues in sync with Action in the `vimr` Python script.
private enum VimRUrlAction: String {
  case activate = "activate"
  case open = "open"
  case newWindow = "open-in-new-window"
  case separateWindows = "open-in-separate-windows"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet var debugMenu: NSMenuItem!

  fileprivate let disposeBag = DisposeBag()

  fileprivate let changeSubject = PublishSubject<Any>()
  fileprivate let changeSink: Observable<Any>

  fileprivate let actionSubject = PublishSubject<Any>()
  fileprivate let actionSink: Observable<Any>

  fileprivate let prefStore: PrefStore

  fileprivate let mainWindowManager: MainWindowManager
  fileprivate let openQuicklyWindowManager: OpenQuicklyWindowManager
  fileprivate let prefWindowComponent: PrefWindowComponent

  fileprivate let fileItemService = FileItemService()
  
  fileprivate var quitWhenAllWindowsAreClosed = false
  fileprivate var launching = true

  override init() {
    self.actionSink = self.actionSubject.asObservable()
    self.changeSink = self.changeSubject.asObservable()

    self.prefStore = PrefStore(source: self.actionSink)

    self.fileItemService.set(ignorePatterns: self.prefStore.data.general.ignorePatterns)

    self.prefWindowComponent = PrefWindowComponent(source: self.changeSink, initialData: self.prefStore.data)
    self.mainWindowManager = MainWindowManager(source: self.changeSink,
                                               fileItemService: self.fileItemService,
                                               initialData: self.prefStore.data)
    self.openQuicklyWindowManager = OpenQuicklyWindowManager(source: self.changeSink,
                                                             fileItemService: self.fileItemService)

    super.init()

    self.prefStore.sink
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribeNext { [unowned self] data in
        if data.general.ignorePatterns == self.fileItemService.ignorePatterns {
          return
        }

        self.fileItemService.set(ignorePatterns: data.general.ignorePatterns)
      }
      .addDisposableTo(self.disposeBag)

    self.mainWindowManager.sink
      .filter { $0 is MainWindowEvent || $0 is MainWindowAction }
      .subscribeNext { [unowned self] event in
        switch event {
        case let MainWindowAction.openQuickly(mainWindow: mainWindow):
          self.openQuicklyWindowManager.open(forMainWindow: mainWindow)
        case MainWindowEvent.allWindowsClosed:
          if self.quitWhenAllWindowsAreClosed {
            NSApp.stop(self)
          }
        default:
          return
        }
      }.addDisposableTo(self.disposeBag)

    [ self.prefStore ]
      .map { $0.sink }
      .toMergedObservables()
      .subscribe(self.changeSubject)
      .addDisposableTo(self.disposeBag)

    [ self.prefWindowComponent ]
      .map { $0.sink }
      .toMergedObservables()
      .subscribe(self.actionSubject)
      .addDisposableTo(self.disposeBag)
  }
}

// MARK: - NSApplicationDelegate
extension AppDelegate {

  func applicationWillFinishLaunching(_: Notification) {
    self.launching = true
    
    let appleEventManager = NSAppleEventManager.shared()
    appleEventManager.setEventHandler(self,
                                      andSelector: #selector(AppDelegate.handleGetUrlEvent(_:withReplyEvent:)),
                                      forEventClass: UInt32(kInternetEventClass),
                                      andEventID: UInt32(kAEGetURL))
  }

  func applicationDidFinishLaunching(_: Notification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.launching = false

    #if DEBUG
      self.debugMenu.isHidden = false
    #endif
  }

  func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
    if self.launching {
      if self.prefStore.data.general.openNewWindowWhenLaunching {
        self.newDocument(self)
        return true
      }
    } else {
      if self.prefStore.data.general.openNewWindowOnReactivation {
        self.newDocument(self)
        return true
      }
    }

    return false
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
    if self.mainWindowManager.hasDirtyWindows() {
      let alert = NSAlert()
      alert.addButton(withTitle: "Cancel")
      alert.addButton(withTitle: "Discard and Quit")
      alert.messageText = "There are windows with unsaved buffers!"
      alert.alertStyle = .warning

      if alert.runModal() == NSAlertSecondButtonReturn {
        self.quitWhenAllWindowsAreClosed = true
        self.mainWindowManager.closeAllWindowsWithoutSaving()
      }

      return .terminateCancel
    }

    if self.mainWindowManager.hasMainWindow() {
      self.quitWhenAllWindowsAreClosed = true
      self.mainWindowManager.closeAllWindows()

      return .terminateCancel
    }

    // There are no open main window, then just quit.
    return .terminateNow
  }
  
  // For drag & dropping files on the App icon.
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { URL(fileURLWithPath: $0) }
    self.mainWindowManager.newMainWindow(urls: urls)
    sender.reply(toOpenOrPrint: .success)
  }
}

// MARK: - AppleScript
extension AppDelegate {
  
  func handleGetUrlEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptor(forKeyword: UInt32(keyDirectObject))?.stringValue else {
      return
    }
    
    guard let url = URL(string: urlString) else {
      return
    }
    
    guard url.scheme == "vimr" else {
      return
    }
    
    guard let rawAction = url.host else {
      return
    }
    
    guard let action = VimRUrlAction(rawValue: rawAction) else {
      return
    }
    
    let queryParams = url.query?.components(separatedBy: "&")
    let urls = queryParams?
      .filter { $0.hasPrefix(filePrefix) }
      .flatMap { $0.without(prefix: filePrefix).removingPercentEncoding }
      .map { URL(fileURLWithPath: $0) } ?? []
    let cwd = queryParams?
      .filter { $0.hasPrefix(cwdPrefix) }
      .flatMap { $0.without(prefix: cwdPrefix).removingPercentEncoding }
      .map { URL(fileURLWithPath: $0) }
      .first ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    
    switch action {
    case .activate, .newWindow:
      self.mainWindowManager.newMainWindow(urls: urls, cwd: cwd)
      return
    case .open:
      self.mainWindowManager.openInKeyMainWindow(urls: urls, cwd: cwd)
      return
    case .separateWindows:
      urls.forEach { self.mainWindowManager.newMainWindow(urls: [$0], cwd: cwd) }
      return
    }
  }
}

// MARK: - IBActions
extension AppDelegate {

  @IBAction func showPrefWindow(_ sender: AnyObject!) {
    self.prefWindowComponent.show()
  }
  
  @IBAction func newDocument(_ sender: AnyObject!) {
    self.mainWindowManager.newMainWindow()
  }

  // Invoked when no main window is open.
  @IBAction func openDocument(_ sender: AnyObject!) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.begin { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }

      self.mainWindowManager.newMainWindow(urls: panel.urls)
    }
  }
}
