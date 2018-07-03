/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import Sparkle
import CocoaFontAwesome

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

  enum Action {

    case newMainWindow(urls: [URL], cwd: URL, nvimArgs: [String]?, cliPipePath: String?, envDict: [String: String]?)
    case openInKeyWindow(urls: [URL], cwd: URL, cliPipePath: String?)

    case preferences
  }

  override init() {
    let baseServerUrl = URL(string: "http://localhost:\(NetUtils.openPort())")!

    var initialAppState: AppState
    if let stateDict = UserDefaults.standard.value(forKey: PrefService.compatibleVersion) as? [String: Any] {
      initialAppState = AppState(dict: stateDict) ?? .default
    } else {
      if let oldDict = UserDefaults.standard.value(forKey: PrefService.lastCompatibleVersion) as? [String: Any] {
        initialAppState = Pref128ToCurrentConverter.appState(from: oldDict)
      } else {
        initialAppState = .default
      }
    }
    initialAppState.mainWindowTemplate.htmlPreview.server = Marked(
      baseServerUrl.appendingPathComponent(HtmlPreviewToolReducer.selectFirstPath)
    )

    self.stateContext = Context(baseServerUrl: baseServerUrl, state: initialAppState)
    self.emit = self.stateContext.actionEmitter.typedEmit()

    self.openNewMainWindowOnLaunch = initialAppState.openNewMainWindowOnLaunch
    self.openNewMainWindowOnReactivation = initialAppState.openNewMainWindowOnReactivation
    self.useSnapshot = initialAppState.useSnapshotUpdate

    let source = self.stateContext.stateSource
    self.uiRoot = UiRoot(source: source, emitter: self.stateContext.actionEmitter, state: initialAppState)

    super.init()

    NSUserNotificationCenter.default.delegate = self

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { appState in
        self.hasMainWindows = !appState.mainWindows.isEmpty
        self.hasDirtyWindows = appState.mainWindows.values.reduce(false) { $1.isDirty ? true : $0 }

        self.openNewMainWindowOnLaunch = appState.openNewMainWindowOnLaunch
        self.openNewMainWindowOnReactivation = appState.openNewMainWindowOnReactivation

        if self.useSnapshot != appState.useSnapshotUpdate {
          self.useSnapshot = appState.useSnapshotUpdate
          self.setSparkleUrl(self.useSnapshot)
        }

        if appState.quit {
          NSApp.terminate(self)
        }
      })
      .disposed(by: self.disposeBag)

    // FIXME: GH-611: https://github.com/qvacua/vimr/issues/611
    // Check whether FontAwesome can be loaded. If not, show a warning.
    // We don't know yet why this happens to some users.
    DispatchQueue.main.async {
      guard NSFont.fontAwesome(ofSize: 13) == nil else {
        return
      }

      let notification = NSUserNotification()
      notification.title = "FontAwesome could not be loaded."
      notification.subtitle = "Unfortunately we don't know yet what is causing this."
      notification.informativeText = """
        We use the FontAwesome font for icons in the tools, e.g. the file browser. Those icons are now shown as ?.
        You can track the progress on this issue at GitHub issue 611.
      """
      NSUserNotificationCenter.default.deliver(notification)
    }
  }

  private let stateContext: Context
  private let emit: (Action) -> Void

  private let uiRoot: UiRoot

  private var hasDirtyWindows = false
  private var hasMainWindows = false

  private var openNewMainWindowOnLaunch: Bool
  private var openNewMainWindowOnReactivation: Bool
  private var useSnapshot: Bool

  private let disposeBag = DisposeBag()

  private var launching = true

  private func setSparkleUrl(_ snapshot: Bool) {
    if snapshot {
      updater.feedURL = URL(
        string: "https://raw.githubusercontent.com/qvacua/vimr/develop/appcast_snapshot.xml"
      )
    } else {
      updater.feedURL = URL(
        string: "https://raw.githubusercontent.com/qvacua/vimr/master/appcast.xml"
      )
    }
  }
}

// MARK: - NSApplicationDelegate
extension AppDelegate {

  func applicationWillFinishLaunching(_: Notification) {
    self.launching = true

    let appleEventManager = NSAppleEventManager.shared()
    appleEventManager.setEventHandler(self,
                                      andSelector: #selector(AppDelegate.handle(getUrlEvent:replyEvent:)),
                                      forEventClass: UInt32(kInternetEventClass),
                                      andEventID: UInt32(kAEGetURL))
  }

  func applicationDidFinishLaunching(_: Notification) {
    self.launching = false

#if DEBUG
    NSApp.mainMenu?.items.first { $0.identifier == debugMenuItemIdentifier }?.isHidden = false
#endif
  }

  func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
    if self.launching {
      if self.openNewMainWindowOnLaunch {
        self.newDocument(self)
        return true
      }
    } else {
      if self.openNewMainWindowOnReactivation {
        self.newDocument(self)
        return true
      }
    }

    return false
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    self.stateContext.savePrefs()

    if self.hasDirtyWindows && self.hasMainWindows {
      let alert = NSAlert()
      alert.addButton(withTitle: "Cancel")
      let discardAndQuitButton = alert.addButton(withTitle: "Discard and Quit")
      alert.messageText = "There are windows with unsaved buffers!"
      alert.alertStyle = .warning
      discardAndQuitButton.keyEquivalentModifierMask = .command
      discardAndQuitButton.keyEquivalent = "d"

      if alert.runModal() == .alertSecondButtonReturn {
        self.uiRoot.prepareQuit()
        return .terminateNow
      }

      return .terminateCancel
    }

    if self.hasMainWindows {
      self.uiRoot.prepareQuit()
      return .terminateNow
    }

    // There are no open main window, then just quit.
    return .terminateNow
  }

  // For drag & dropping files on the App icon.
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { URL(fileURLWithPath: $0) }
    self.emit(.newMainWindow(urls: urls, cwd: FileUtils.userHomeUrl, nvimArgs: nil, cliPipePath: nil, envDict: nil))

    sender.reply(toOpenOrPrint: .success)
  }
}

// MARK: - AppleScript
extension AppDelegate {

  @objc func handle(getUrlEvent event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
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

    let rawParams = url.query?.components(separatedBy: "&") ?? []

    guard let pipePath = queryParam(pipePathPrefix, from: rawParams, transforming: identity).first else {
      let alert = NSAlert()
      alert.alertStyle = .informational
      alert.messageText = "Outdated Command Line Tool?"
      alert.informativeText = "It seems that the installed vimr command line tool is outdated." +
                              "Please re-install it from the General Preferences."
      alert.runModal()

      return
    }

    guard FileManager.default.fileExists(atPath: pipePath) else {
      // Use pipePath as a kind of nonce
      return
    }

    let dict = try? FileManager.default.attributesOfItem(atPath: pipePath) as NSDictionary
    guard dict?.filePosixPermissions() == 0o600 else {
      // Use pipePath as a kind of nonce
      return
    }

    let envDict: [String: String]?
    if let envPath = queryParam(envPathPrefix, from: rawParams, transforming: identity).first {
      envDict = stringDict(from: URL(fileURLWithPath: envPath))
      if FileManager.default.fileExists(atPath: envPath) {
        do {
          try FileManager.default.removeItem(atPath: envPath)
        } catch {
          fileLog.error(error.localizedDescription)
        }
      }
    } else {
      envDict = nil
    }

    let urls = queryParam(filePrefix, from: rawParams, transforming: { URL(fileURLWithPath: $0) })
    let cwd = queryParam(cwdPrefix,
                         from: rawParams,
                         transforming: { URL(fileURLWithPath: $0) }).first ?? FileUtils.userHomeUrl
    let wait = queryParam(waitPrefix, from: rawParams, transforming: { $0 == "true" ? true : false }).first ?? false

    if wait == false {
      _ = Darwin.close(Darwin.open(pipePath, O_WRONLY))
    }

    // If we don't do this, the window is active, but not in front.
    NSApp.activate(ignoringOtherApps: true)

    switch action {

    case .activate, .newWindow:
      self.emit(.newMainWindow(urls: urls, cwd: cwd, nvimArgs: nil, cliPipePath: pipePath, envDict: envDict))

    case .open:
      self.emit(.openInKeyWindow(urls: urls, cwd: cwd, cliPipePath: pipePath))

    case .separateWindows:
      urls.forEach {
        self.emit(.newMainWindow(urls: [$0], cwd: cwd, nvimArgs: nil, cliPipePath: pipePath, envDict: nil))
      }

    case .nvim:
      self.emit(.newMainWindow(urls: [],
                               cwd: cwd,
                               nvimArgs: queryParam(nvimArgsPrefix, from: rawParams, transforming: identity),
                               cliPipePath: pipePath,
                               envDict: envDict))

    }
  }

  private func stringDict(from jsonUrl: URL) -> [String: String]? {
    guard let data = try? Data(contentsOf: jsonUrl) else {
      return nil
    }

    do {
      return try JSONSerialization.jsonObject(with: data) as? [String: String]
    } catch {
      fileLog.error(error.localizedDescription)
    }

    return nil
  }

  private func queryParam<T>(_ prefix: String,
                             from rawParams: [String],
                             transforming transform: (String) -> T) -> [T] {

    return rawParams
      .filter { $0.hasPrefix(prefix) }
      .compactMap { $0.without(prefix: prefix).removingPercentEncoding }
      .map(transform)
  }
}

// MARK: - IBActions
extension AppDelegate {

  @IBAction func checkForUpdates(_ sender: Any?) {
    updater.checkForUpdates(sender)
  }

  @IBAction func newDocument(_ sender: Any?) {
    self.emit(.newMainWindow(urls: [], cwd: FileUtils.userHomeUrl, nvimArgs: nil, cliPipePath: nil, envDict: nil))
  }

  @IBAction func openInNewWindow(_ sender: Any?) {
    self.openDocument(sender)
  }

  @IBAction func showPrefWindow(_ sender: Any?) {
    self.emit(.preferences)
  }

  // Invoked when no main window is open.
  @IBAction func openDocument(_: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.begin { result in
      guard result == .OK else {
        return
      }

      let urls = panel.urls
      let commonParentUrl = FileUtils.commonParent(of: urls)

      self.emit(.newMainWindow(urls: urls, cwd: commonParentUrl, nvimArgs: nil, cliPipePath: nil, envDict: nil))
    }
  }
}

// MARK: - NSUserNotificationCenterDelegate
extension AppDelegate {

  public func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent _: NSUserNotification) -> Bool {
    return true
  }
}

// Keep the rawValues in sync with Action in the `vimr` Python script.
private enum VimRUrlAction: String {
  case activate = "activate"
  case open = "open"
  case newWindow = "open-in-new-window"
  case separateWindows = "open-in-separate-windows"
  case nvim = "nvim"
}

private let updater = SUUpdater()

private let debugMenuItemIdentifier = NSUserInterfaceItemIdentifier("debug-menu-item")

// Keep in sync with QueryParamKey in the `vimr` Python script.
private let filePrefix = "file="
private let cwdPrefix = "cwd="
private let nvimArgsPrefix = "nvim-args="
private let pipePathPrefix = "pipe-path="
private let waitPrefix = "wait="
private let envPathPrefix = "env-path="
