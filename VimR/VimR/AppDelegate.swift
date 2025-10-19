/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import CommonsObjC
import DictionaryCoding
import os
import PureLayout
import Sparkle
import UserNotifications

let debugMenuItemIdentifier = NSUserInterfaceItemIdentifier("debug-menu-item")

final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
  var useSnapshotChannel = false

  func feedURLString(for _: SPUUpdater) -> String? {
    if self.useSnapshotChannel {
      "https://raw.githubusercontent.com/qvacua/vimr/master/appcast_snapshot.xml"
    } else {
      "https://raw.githubusercontent.com/qvacua/vimr/master/appcast.xml"
    }
  }
}

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  struct OpenConfig {
    var urls: [URL]
    var cwd: URL

    var cliPipePath: String?
    var nvimArgs: [String]?
    var additionalEnvs: [String: String]
    var line: Int?
  }

  enum Action {
    case newMainWindow(config: OpenConfig)
    case openInKeyWindow(config: OpenConfig)

    case preferences
  }

  let uuid = UUID()

  @IBOutlet var customConfigWindow: NSWindow!

  override init() {
    let baseServerUrl = URL(string: "http://localhost:\(NetUtils.openPort())")!

    var initialAppState: AppState

    let dictDecoder = DictionaryDecoder()
    if let stateDict = UserDefaults.standard
      .value(forKey: PrefMiddleware.compatibleVersion) as? [String: Any],
      let state = try? dictDecoder.decode(AppState.self, from: stateDict)
    {
      initialAppState = state
    } else {
      initialAppState = .default
    }

    initialAppState.mainWindowTemplate.htmlPreview.server = nil

    self.context = ReduxContext(baseServerUrl: baseServerUrl, state: initialAppState)
    self.emit = self.context.actionEmitter.typedEmit()

    self.openNewMainWindowOnLaunch = initialAppState.openNewMainWindowOnLaunch
    self.openNewMainWindowOnReactivation = initialAppState.openNewMainWindowOnReactivation

    self.updaterDelegate.useSnapshotChannel = initialAppState.useSnapshotUpdate
    self.updaterController = SPUStandardUpdaterController(
      startingUpdater: false,
      updaterDelegate: self.updaterDelegate,
      userDriverDelegate: nil
    )

    super.init()

    UNUserNotificationCenter.current().delegate = self
  }

  // awakeFromNib is not @MainActor isolated
  // https://www.massicotte.org/awakefromnib
  override func awakeFromNib() {
    super.awakeFromNib()

    MainActor.assumeIsolated {
      // We want to build the menu items tree at some point, eg in the init() of
      // ShortcutsPref. We have to do that *after* the MainMenu.xib is loaded.
      // Therefore, we use optional var for the self.uiRoot. Ugly, but, well...
      self.uiRoot = UiRoot(context: self.context, state: self.context.state)

      self.setupCustomConfigWindow()

      self.context.subscribe(uuid: self.uuid) { appState in
        self.hasMainWindows = !appState.mainWindows.isEmpty
        self.hasDirtyWindows = appState.mainWindows.values.contains(where: { $0.isDirty })

        self.openNewMainWindowOnLaunch = appState.openNewMainWindowOnLaunch
        self.openNewMainWindowOnReactivation = appState.openNewMainWindowOnReactivation

        if self.updaterDelegate.useSnapshotChannel != appState.useSnapshotUpdate {
          self.updaterDelegate.useSnapshotChannel = appState.useSnapshotUpdate
        }

        if appState.quit { NSApp.terminate(self) }
      }
    }
  }

  private let context: ReduxContext
  private let emit: (Action) -> Void

  private var uiRoot: UiRoot?

  private var hasDirtyWindows = false
  private var hasMainWindows = false

  private var openNewMainWindowOnLaunch: Bool
  private var openNewMainWindowOnReactivation: Bool

  private var launching = true

  private let updaterController: SPUStandardUpdaterController
  private let updaterDelegate = UpdaterDelegate()

  private let logger = Logger(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.general
  )

  private var customConfigTextField = NSTextField(forAutoLayout: ())

  private func setupCustomConfigWindow() {
    // We know that the window and its contentView exist
    let win = self.customConfigWindow!
    let view = win.contentView!

    let title = self.titleTextField(title: "NVIM_APPNAME:")
    let location = self.customConfigTextField
    let info = self.infoTextField(markdown: """
    Nvim will be started with the config directory `$HOME/.config/<NVIM_APPNAME>`.
    See [Nvim's documentation](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)
    for more details.
    """)

    let okButton = NSButton(forAutoLayout: ())
    okButton.title = "OK"
    okButton.keyEquivalent = "\r"
    okButton.bezelStyle = .rounded
    okButton.target = self
    okButton.action = #selector(customConfigOkAction(_:))

    let cancelButton = NSButton(forAutoLayout: ())
    cancelButton.title = "Cancel"
    cancelButton.keyEquivalent = "\u{1b}" // ESC
    cancelButton.bezelStyle = .rounded
    cancelButton.target = self
    cancelButton.action = #selector(customConfigCancelAction(_:))

    view.addSubview(title)
    view.addSubview(location)
    view.addSubview(info)
    view.addSubview(okButton)
    view.addSubview(cancelButton)

    title.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    title.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    location.autoPinEdge(.left, to: .right, of: title, withOffset: 5)
    location.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    location.autoSetDimension(.width, toSize: 300)
    location.autoAlignAxis(.baseline, toSameAxisOf: title)

    info.autoPinEdge(.left, to: .left, of: location)
    info.autoPinEdge(.top, to: .bottom, of: location, withOffset: 5)
    info.autoPinEdge(toSuperviewEdge: .right, withInset: 18)

    okButton.autoPinEdge(.top, to: .bottom, of: info, withOffset: 18)
    okButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    okButton.autoPinEdge(toSuperviewEdge: .right, withInset: 18)

    cancelButton.autoPinEdge(.top, to: .top, of: okButton)
    cancelButton.autoPinEdge(.right, to: .left, of: okButton, withOffset: -8)
  }

  private func titleTextField(title: String) -> NSTextField {
    let field = NSTextField.defaultTitleTextField()
    field.alignment = .right
    field.stringValue = title
    return field
  }

  func infoTextField(markdown: String) -> NSTextField {
    let field = NSTextField(forAutoLayout: ())
    field.backgroundColor = NSColor.clear
    field.isEditable = false
    field.isBordered = false
    field.usesSingleLineMode = false

    // both are needed, otherwise hyperlink won't accept mousedown
    field.isSelectable = true
    field.allowsEditingTextAttributes = true

    field.attributedStringValue = NSAttributedString.infoLabel(markdown: markdown)

    return field
  }
}

// MARK: - NSApplicationDelegate

extension AppDelegate {
  func applicationWillFinishLaunching(_: Notification) {
    self.launching = true

    let appleEventManager = NSAppleEventManager.shared()
    appleEventManager.setEventHandler(
      self,
      andSelector: #selector(AppDelegate.handle(getUrlEvent:replyEvent:)),
      forEventClass: UInt32(kInternetEventClass),
      andEventID: UInt32(kAEGetURL)
    )
  }

  func applicationDidFinishLaunching(_: Notification) {
    self.launching = false

    self.updaterController.startUpdater()

    #if DEBUG
    NSApp.mainMenu?.items.first { $0.identifier == debugMenuItemIdentifier }?.isHidden = false
    #else
    // defaults write com.qvacua.VimR enable-debug-menu 1
    if UserDefaults.standard.bool(forKey: "enable-debug-menu") {
      NSApp.mainMenu?.items.first { $0.identifier == debugMenuItemIdentifier }?.isHidden = false
    }
    #endif
  }

  func applicationOpenUntitledFile(_: NSApplication) -> Bool {
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

  func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    self.context.savePrefs()

    Task {
      guard self.hasMainWindows else {
        await self.uiRoot?.prepareQuit()
        NSApplication.shared.reply(toApplicationShouldTerminate: true)
        return
      }

      if await self.uiRoot?.hasBlockedWindows() == true {
        let alert = NSAlert()
        alert.messageText = "There are windows waiting for your input."
        alert.alertStyle = .informational
        alert.runModal()

        return
      }

      if self.hasDirtyWindows {
        let alert = NSAlert()
        let cancelButton = alert.addButton(withTitle: "Cancel")
        let discardAndQuitButton = alert.addButton(withTitle: "Discard and Quit")
        cancelButton.keyEquivalent = "\u{1b}"
        alert.messageText = "There are windows with unsaved buffers!"
        alert.alertStyle = .warning
        discardAndQuitButton.keyEquivalentModifierMask = .command
        discardAndQuitButton.keyEquivalent = "d"

        if alert.runModal() == .alertSecondButtonReturn {
          self.updateMainWindowTemplateBeforeQuitting()
          await self.uiRoot?.prepareQuit()

          NSApplication.shared.reply(toApplicationShouldTerminate: true)
          return
        }

        return
      }

      self.updateMainWindowTemplateBeforeQuitting()
      await self.uiRoot?.prepareQuit()

      NSApplication.shared.reply(toApplicationShouldTerminate: true)
    }

    return .terminateLater
  }

  // For drag & dropping files on the App icon.
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { URL(fileURLWithPath: $0) }
    let config = OpenConfig(
      urls: urls, cwd: FileUtils.userHomeUrl, cliPipePath: nil, nvimArgs: nil, additionalEnvs: [:],
      line: nil
    )
    switch self.context.state.openFilesFromApplicationsAction {
    case .inCurrentWindow:
      self.emit(.openInKeyWindow(config: config))
    default:
      self.emit(.newMainWindow(config: config))
    }

    sender.reply(toOpenOrPrint: .success)
  }

  private func updateMainWindowTemplateBeforeQuitting() {
    self.context.savePrefs()
  }
}

// MARK: - AppleScript

extension AppDelegate {
  @objc func handle(
    getUrlEvent event: NSAppleEventDescriptor,
    replyEvent _: NSAppleEventDescriptor
  ) {
    guard let urlString = event.paramDescriptor(forKeyword: UInt32(keyDirectObject))?.stringValue
    else { return }

    guard let url = URL(string: urlString) else { return }

    guard url.scheme == "vimr" else { return }

    guard let rawAction = url.host else { return }

    guard let action = VimRUrlAction(rawValue: rawAction) else { return }

    let rawParams = url.query?.components(separatedBy: "&") ?? []

    guard let pipePath = queryParam(pipePathPrefix, from: rawParams, transforming: identity).first
    else {
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

    let additionalEnvs: [String: String]
    if let envPath = queryParam(envPathPrefix, from: rawParams, transforming: identity).first {
      additionalEnvs = self.stringDict(from: URL(fileURLWithPath: envPath)) ?? [:]
      if FileManager.default.fileExists(atPath: envPath) {
        do {
          try FileManager.default.removeItem(atPath: envPath)
        } catch {
          self.logger.error(error.localizedDescription)
        }
      }
    } else {
      additionalEnvs = [:]
    }

    let line = self.queryParam(linePrefix, from: rawParams, transforming: { Int($0) })
      .compactMap(\.self).first
    let urls = self.queryParam(
      filePrefix,
      from: rawParams,
      transforming: { URL(fileURLWithPath: $0) }
    )
    let cwd = self.queryParam(
      cwdPrefix,
      from: rawParams,
      transforming: { URL(fileURLWithPath: $0) }
    ).first ?? FileUtils.userHomeUrl
    let wait = self.queryParam(
      waitPrefix,
      from: rawParams,
      transforming: { $0 == "true" ? true : false }
    ).first ?? false

    if wait == false { _ = Darwin.close(Darwin.open(pipePath, O_WRONLY)) }

    // If we don't do this, the window is active, but not in front.
    NSApp.activate(ignoringOtherApps: true)

    switch action {
    case .activate, .newWindow:
      let config = OpenConfig(
        urls: urls,
        cwd: cwd,
        cliPipePath: pipePath,
        nvimArgs: nil,
        additionalEnvs: additionalEnvs,
        line: line
      )
      self.emit(.newMainWindow(config: config))

    case .open:
      let config = OpenConfig(
        urls: urls,
        cwd: cwd,
        cliPipePath: pipePath,
        nvimArgs: nil,
        additionalEnvs: additionalEnvs,
        line: line
      )
      self.emit(.openInKeyWindow(config: config))

    case .separateWindows:
      for url in urls {
        let config = OpenConfig(
          urls: [url],
          cwd: cwd,
          cliPipePath: pipePath,
          nvimArgs: nil,
          additionalEnvs: [:],
          line: line
        )
        self.emit(.newMainWindow(config: config))
      }

    case .nvim:
      let config = OpenConfig(
        urls: urls,
        cwd: cwd,
        cliPipePath: pipePath,
        nvimArgs: queryParam(
          nvimArgsPrefix,
          from: rawParams,
          transforming: identity
        ),
        additionalEnvs: additionalEnvs,
        line: line
      )
      self.emit(.newMainWindow(config: config))
    }
  }

  private func stringDict(from jsonUrl: URL) -> [String: String]? {
    guard let data = try? Data(contentsOf: jsonUrl) else {
      return nil
    }

    do {
      return try JSONSerialization.jsonObject(with: data) as? [String: String]
    } catch {
      self.logger.error(error.localizedDescription)
    }

    return nil
  }

  private func queryParam<T>(
    _ prefix: String,
    from rawParams: [String],
    transforming transform: (String) -> T
  ) -> [T] {
    rawParams
      .filter { $0.hasPrefix(prefix) }
      .compactMap { $0.without(prefix: prefix).removingPercentEncoding }
      .map(transform)
  }
}

// MARK: - IBActions

extension AppDelegate {
  @IBAction func checkForUpdates(_ sender: Any?) {
    self.updaterController.checkForUpdates(sender)
  }

  @IBAction func newDocument(_: Any?) {
    let config = OpenConfig(
      urls: [], cwd: FileUtils.userHomeUrl, cliPipePath: nil, nvimArgs: nil, additionalEnvs: [:],
      line: nil
    )
    self.emit(.newMainWindow(config: config))
  }

  @IBAction func newDocumentWithCustomConfigLocation(_: Any?) {
    NSApp.runModal(for: self.customConfigWindow)
  }

  @objc private func customConfigOkAction(_: Any?) {
    let appName = self.customConfigTextField.stringValue.trimmingCharacters(in: .whitespaces)
    guard !appName.isEmpty else {
      self.customConfigTextField.layer?.borderColor = NSColor.systemRed.cgColor
      self.customConfigTextField.layer?.borderWidth = 3.0
      return
    }

    self.stopCustomConfigWindow()

    self.emit(.newMainWindow(config: OpenConfig(
      urls: [], cwd: FileUtils.userHomeUrl, cliPipePath: nil, nvimArgs: nil,
      additionalEnvs: ["NVIM_APPNAME": appName],
      line: nil
    )))
  }
  
  private func stopCustomConfigWindow() {
    NSApp.stopModal()
    self.customConfigWindow.orderOut(nil)
    self.customConfigTextField.stringValue = ""
    self.customConfigTextField.layer?.borderWidth = 0

  }

  @objc private func customConfigCancelAction(_: Any?) {
    self.stopCustomConfigWindow()
  }

  @IBAction func openInNewWindow(_ sender: Any?) { self.openDocument(sender) }

  @IBAction func showPrefWindow(_: Any?) { self.emit(.preferences) }

  // Invoked when no main window is open.
  @IBAction func openDocument(_: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.begin { result in
      guard result == .OK else { return }

      let urls = panel.urls
      let commonParentUrl = FileUtils.commonParent(of: urls)

      let config = OpenConfig(
        urls: urls, cwd: commonParentUrl, cliPipePath: nil, nvimArgs: nil, additionalEnvs: [:],
        line: nil
      )
      self.emit(.newMainWindow(config: config))
    }
  }
}

// MARK: - NSUserNotificationCenterDelegate

extension AppDelegate {
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification
  ) async -> UNNotificationPresentationOptions { .banner }
}

// Keep the rawValues in sync with Action in the `vimr` Python script.
private enum VimRUrlAction: String {
  case activate
  case open
  case newWindow = "open-in-new-window"
  case separateWindows = "open-in-separate-windows"
  case nvim
}

// Keep in sync with QueryParamKey in the `vimr` Python script.
private let filePrefix = "file="
private let cwdPrefix = "cwd="
private let nvimArgsPrefix = "nvim-args="
private let pipePathPrefix = "pipe-path="
private let waitPrefix = "wait="
private let envPathPrefix = "env-path="
private let linePrefix = "line="
