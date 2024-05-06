/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import os
import PureLayout
import RxSwift
import Tabs
import UserNotifications
import Workspace

final class MainWindow: NSObject,
  UiComponent,
  NSWindowDelegate,
  NSUserInterfaceValidations,
  WorkspaceDelegate,
  NvimViewDelegate
{
  typealias StateType = State

  let disposeBag = DisposeBag()

  let uuid: UUID
  let emit: (UuidAction<Action>) -> Void

  let windowController: NSWindowController
  var window: NSWindow { self.windowController.window! }

  let workspace: Workspace
  let neoVimView: NvimView

  var activateAsciiImInInsertMode: Bool {
    get { self.neoVimView.activateAsciiImInNormalMode }
    set { self.neoVimView.activateAsciiImInNormalMode = newValue }
  }

  weak var shortcutService: ShortcutService?

  let scrollDebouncer = Debouncer<Action>(interval: .milliseconds(750))
  let cursorDebouncer = Debouncer<Action>(interval: .milliseconds(750))
  var editorPosition = Marked(Position.beginning)

  let tools: [Tools: WorkspaceTool]

  var previewContainer: WorkspaceTool?
  var fileBrowserContainer: WorkspaceTool?
  var buffersListContainer: WorkspaceTool?
  var htmlPreviewContainer: WorkspaceTool?

  var theme = Theme.default

  var titlebarThemed = false
  var repIcon: NSButton?
  var titleView: NSTextField?

  var closeWindow = false
  var isClosing = false
  let cliPipePath: String?

  required init(
    source: Observable<StateType>,
    emitter: ActionEmitter,
    state: StateType
  ) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    self.cliPipePath = state.cliPipePath
    self.goToLineFromCli = state.goToLineFromCli

    self.windowController = NSWindowController(
      windowNibName: NSNib.Name("MainWindow")
    )

    var sourceFileUrls = [URL]()
    if let sourceFileUrl = Bundle(for: MainWindow.self)
      .url(forResource: "com.qvacua.VimR", withExtension: "vim")
    {
      sourceFileUrls.append(sourceFileUrl)
    }

    // FIXME: GH-349: Make usesCustomTabBar configurable via pref
    let neoVimViewConfig = NvimView.Config(
      usesCustomTabBar: state.appearance.usesCustomTab,
      useInteractiveZsh: state.useInteractiveZsh,
      cwd: state.cwd,
      nvimBinary: state.nvimBinary,
      nvimArgs: state.nvimArgs,
      envDict: state.envDict,
      sourceFiles: sourceFileUrls
    )
    self.neoVimView = NvimView(frame: .zero, config: neoVimViewConfig)
    self.neoVimView.configureForAutoLayout()

    self.workspace = Workspace(mainView: self.neoVimView)

    var tools: [Tools: WorkspaceTool] = [:]
    if state.activeTools[.preview] == true {
      self.preview = MarkdownTool(source: source, emitter: emitter, state: state)
      let previewConfig = WorkspaceTool.Config(
        title: "Markdown",
        view: self.preview!,
        customMenuItems: self.preview!.menuItems
      )
      self.previewContainer = WorkspaceTool(previewConfig)
      self.previewContainer!.dimension = state.tools[.preview]?.dimension ?? 250
      tools[.preview] = self.previewContainer
    }

    if state.activeTools[.htmlPreview] == true {
      self.htmlPreview = HtmlPreviewTool(
        source: source,
        emitter: emitter,
        state: state
      )
      let htmlPreviewConfig = WorkspaceTool.Config(
        title: "HTML",
        view: self.htmlPreview!,
        customToolbar: self.htmlPreview!.innerCustomToolbar
      )
      self.htmlPreviewContainer = WorkspaceTool(htmlPreviewConfig)
      self.htmlPreviewContainer!.dimension = state.tools[.htmlPreview]?
        .dimension ?? 250
      tools[.htmlPreview] = self.htmlPreviewContainer
    }

    if state.activeTools[.fileBrowser] == true {
      self.fileBrowser = FileBrowser(
        source: source, emitter: emitter, state: state
      )
      let fileBrowserConfig = WorkspaceTool.Config(
        title: "Files",
        view: self.fileBrowser!,
        customToolbar: self.fileBrowser!.innerCustomToolbar,
        customMenuItems: self.fileBrowser!.menuItems
      )
      self.fileBrowserContainer = WorkspaceTool(fileBrowserConfig)
      self.fileBrowserContainer!.dimension = state
        .tools[.fileBrowser]?
        .dimension ?? 200
      tools[.fileBrowser] = self.fileBrowserContainer
    }

    if state.activeTools[.buffersList] == true {
      self.buffersList = BuffersList(
        source: source, emitter: emitter, state: state
      )
      let buffersListConfig = WorkspaceTool.Config(
        title: "Buffers",
        view: self.buffersList!
      )
      self.buffersListContainer = WorkspaceTool(buffersListConfig)
      self.buffersListContainer!.dimension = state
        .tools[.buffersList]?
        .dimension ?? 200
      tools[.buffersList] = self.buffersListContainer
    }

    self.tools = tools

    super.init()

    self.window.tabbingMode = .disallowed

    self.fontSmoothing = state.appearance.fontSmoothing
    self.defaultFont = state.appearance.font
    self.linespacing = state.appearance.linespacing
    self.characterspacing = state.appearance.characterspacing
    self.usesLigatures = state.appearance.usesLigatures

    self.editorPosition = state.preview.editorPosition
    self.previewPosition = state.preview.previewPosition

    self.usesTheme = state.appearance.usesTheme

    state.orderedTools.forEach { toolId in
      guard let tool = tools[toolId] else {
        return
      }

      self.workspace.append(
        tool: tool,
        location: state.tools[toolId]?.location ?? .left
      )
    }

    self.tools.forEach { toolId, toolContainer in
      if state.tools[toolId]?.open == true {
        toolContainer.toggle()
      }
    }

    if !state.isToolButtonsVisible {
      self.workspace.toggleToolButtons()
    }

    if !state.isAllToolsVisible {
      self.workspace.toggleAllTools()
    }

    self.windowController.window?.delegate = self
    self.windowController.nextResponder = NSApplication.shared
    self.workspace.delegate = self

    self.addViews(withTopInset: 0)

    self.neoVimView.usesLiveResize = state.useLiveResize
    self.neoVimView.delegate = self
    self.updateNeoVimAppearance()

    self.setupScrollAndCursorDebouncers()
    self.subscribeToNvimViewEvents()
    self.subscribeToStateChange(source: source)

    self.window.setFrame(state.frame, display: true)
    self.window.makeFirstResponder(self.neoVimView)

    self.openInitialUrlsAndGoToLine(urlsToOpen: state.urlsToOpen)
  }

  func uuidAction(for action: Action) -> UuidAction<Action> {
    UuidAction(uuid: self.uuid, action: action)
  }

  func show() {
    self.windowController.showWindow(self)
  }

  // The following should only be used when Cmd-Q'ing
  func quitNeoVimWithoutSaving() -> Completable {
    self.neoVimView.quitNeoVimWithoutSaving()
  }

  @IBAction func toggleFramerate(_: Any?) { self.neoVimView.toggleFramerateView() }

  // MARK: - Private

  private var currentBuffer: NvimView.Buffer?

  private var goToLineFromCli: Marked<Int>?

  private var fontSmoothing = FontSmoothing.systemSetting
  private var defaultFont = NvimView.defaultFont
  private var linespacing = NvimView.defaultLinespacing
  private var characterspacing = NvimView.defaultCharacterspacing
  private var usesLigatures = true
  private var drawsParallel = false

  private var previewPosition = Marked(Position.beginning)

  private var preview: MarkdownTool?
  private var htmlPreview: HtmlPreviewTool?
  private var fileBrowser: FileBrowser?
  private var buffersList: BuffersList?

  private var usesTheme = true
  private var lastThemeMark = Token()

  let log = OSLog(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.ui
  )

  private func setupScrollAndCursorDebouncers() {
    Observable
      .of(self.scrollDebouncer.observable, self.cursorDebouncer.observable)
      .merge()
      .subscribe(onNext: { [weak self] action in
        guard let action = self?.uuidAction(for: action) else { return }
        self?.emit(action)
      })
      .disposed(by: self.disposeBag)
  }

  private func subscribeToNvimViewEvents() {
    self.neoVimView.events
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] event in
        switch event {
        case .neoVimStopped: self?.neoVimStopped()

        case let .setTitle(title): self?.set(title: title)

        case let .setDirtyStatus(dirty): self?.set(dirtyStatus: dirty)

        case .cwdChanged: self?.cwdChanged()

        case .bufferListChanged: self?.bufferListChanged()

        case .tabChanged: self?.tabChanged()

        case let .newCurrentBuffer(curBuf): self?.newCurrentBuffer(curBuf)

        case let .bufferWritten(buf): self?.bufferWritten(buf)

        case let .colorschemeChanged(theme): self?.colorschemeChanged(to: theme)

        case let .guifontChanged(font): self?.guifontChanged(to: font)

        case let .ipcBecameInvalid(reason):
          self?.ipcBecameInvalid(reason: reason)

        case .scroll: self?.scroll()

        case let .cursor(position): self?.cursor(to: position)

        case .initVimError: self?.showInitError()

        case let .apiError(error, msg):
          self?.log.error("Got api error with msg '\(msg)' and error: \(error)")

        case let .rpcEvent(params): self?.rpcEventAction(params: params)

        case let .warning(warning): self?.show(warning: warning)

        case .rpcEventSubscribed: break
        }
      }, onError: { error in
        // FIXME: call onError
        self.log.error(error)
      })
      .disposed(by: self.disposeBag)
  }

  private func subscribeToStateChange(source: Observable<StateType>) {
    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.isClosing {
          return
        }

        if state.viewToBeFocused != nil,
           case .neoVimView = state.viewToBeFocused!
        {
          self.window.makeFirstResponder(self.neoVimView)
        }

        self.windowController.setDocumentEdited(state.isDirty)

        if let cwd = state.cwdToSet {
          self.neoVimView.cwd = cwd
          self.neoVimView.tabBar?.cwd = cwd.path
        }

        Completable
          .empty()
          .andThen {
            if state.preview.status == .markdown,
               state.previewTool.isReverseSearchAutomatically,
               state.preview.previewPosition
               .hasDifferentMark(as: self.previewPosition)
            {
              self.previewPosition = state.preview.previewPosition
              return self.neoVimView.cursorGo(
                to: state.preview.previewPosition.payload
              )
            }

            return .empty()
          }
          .andThen(self.open(urls: state.urlsToOpen))
          .andThen {
            if let currentBuffer = state.currentBufferToSet {
              return self.neoVimView.select(buffer: currentBuffer)
            }

            return .empty()
          }
          .andThen {
            if self.goToLineFromCli?.mark != state.goToLineFromCli?.mark {
              self.goToLineFromCli = state.goToLineFromCli
              if let goToLine = self.goToLineFromCli {
                return self.neoVimView.goTo(line: goToLine.payload)
              }
            }

            return .empty()
          }
          .subscribe()
          .disposed(by: self.disposeBag)

        let usesTheme = state.appearance.usesTheme
        let themePrefChanged = state.appearance.usesTheme != self.usesTheme
        let themeChanged = state.appearance.theme.mark != self.lastThemeMark

        if themeChanged {
          self.theme = state.appearance.theme.payload
        }

        _ = changeTheme(
          themePrefChanged: themePrefChanged,
          themeChanged: themeChanged,
          usesTheme: usesTheme,
          forTheme: {
            self.themeTitlebar(grow: !self.titlebarThemed)
            self.window.backgroundColor = state.appearance
              .theme.payload.background.brightening(by: 0.9)

            self.set(workspaceThemeWith: state.appearance.theme.payload)
            self.set(tabsThemeWith: state.appearance.theme.payload)

            self.lastThemeMark = state.appearance.theme.mark
          },
          forDefaultTheme: {
            self.unthemeTitlebar(dueFullScreen: false)
            self.window.backgroundColor = .windowBackgroundColor

            self.workspace.theme = .default
            self.neoVimView.tabBar?.update(theme: .default)
          }
        )

        self.usesTheme = state.appearance.usesTheme

        if self.currentBuffer == nil || self.currentBuffer != state.currentBuffer {
          self.currentBuffer = state.currentBuffer
          if state.appearance.showsFileIcon {
            self.set(repUrl: self.currentBuffer?.url, themed: self.titlebarThemed)
          } else {
            self.set(repUrl: nil, themed: self.titlebarThemed)
          }
        }

        self.neoVimView.isLeftOptionMeta = state.isLeftOptionMeta
        self.neoVimView.isRightOptionMeta = state.isRightOptionMeta

        if self.neoVimView.usesLiveResize != state.useLiveResize {
          self.neoVimView.usesLiveResize = state.useLiveResize
        }

        if self.defaultFont != state.appearance.font
          || self.linespacing != state.appearance.linespacing
          || self.characterspacing != state.appearance.characterspacing
          || self.usesLigatures != state.appearance.usesLigatures
          || self.fontSmoothing != state.appearance.fontSmoothing
        {
          self.fontSmoothing = state.appearance.fontSmoothing
          self.defaultFont = state.appearance.font
          self.linespacing = state.appearance.linespacing
          self.characterspacing = state.appearance.characterspacing
          self.usesLigatures = state.appearance.usesLigatures

          self.updateNeoVimAppearance()
        }
      })
      .disposed(by: self.disposeBag)
  }

  private func openInitialUrlsAndGoToLine(urlsToOpen: [URL: OpenMode]) {
    self
      .open(urls: urlsToOpen)
      .andThen {
        if let goToLine = self.goToLineFromCli {
          return self.neoVimView.goTo(line: goToLine.payload)
        }

        return .empty()
      }
      .subscribe()
      .disposed(by: self.disposeBag)
  }

  private func updateNeoVimAppearance() {
    self.neoVimView.fontSmoothing = self.fontSmoothing
    self.neoVimView.font = self.defaultFont
    self.neoVimView.linespacing = self.linespacing
    self.neoVimView.characterspacing = self.characterspacing
    self.neoVimView.usesLigatures = self.usesLigatures
  }

  private func set(tabsThemeWith _: Theme) {
    var tabsTheme = Tabs.Theme.default

    tabsTheme.foregroundColor = self.theme.foreground
    tabsTheme.backgroundColor = self.theme.background

    tabsTheme.separatorColor = self.theme.background.brightening(by: 0.75)

    tabsTheme.selectedForegroundColor = self.theme.highlightForeground
    tabsTheme.selectedBackgroundColor = self.theme.highlightBackground
		
		tabsTheme.tabBackgroundColor = self.theme.tabBackground;
		tabsTheme.tabForegroundColor = self.theme.tabForeground;

    tabsTheme.tabSelectedIndicatorColor = self.theme.highlightForeground

    self.neoVimView.tabBar?.update(theme: tabsTheme)
  }

  private func set(workspaceThemeWith theme: Theme) {
    var workspaceTheme = Workspace.Theme()
    workspaceTheme.foreground = theme.foreground
    workspaceTheme.background = theme.background

    workspaceTheme.separator = theme.background.brightening(by: 0.75)

    workspaceTheme.barBackground = theme.background
    workspaceTheme.barFocusRing = theme.foreground

    workspaceTheme.barButtonHighlight = theme.background.brightening(by: 0.75)

    workspaceTheme.toolbarForeground = theme.foreground
    workspaceTheme.toolbarBackground = theme.background.brightening(by: 0.75)

    self.workspace.theme = workspaceTheme
  }

  private func open(urls: [URL: OpenMode]) -> Completable {
    if urls.isEmpty {
      return .empty()
    }

    return .concat(
      urls.map { entry -> Completable in
        let url = entry.key
        let mode = entry.value

        switch mode {
        case .default: return self.neoVimView.open(urls: [url])
        case .currentTab: return self.neoVimView.openInCurrentTab(url: url)
        case .newTab: return self.neoVimView.openInNewTab(urls: [url])
        case .horizontalSplit:
          return self.neoVimView.openInHorizontalSplit(urls: [url])
        case .verticalSplit:
          return self.neoVimView.openInVerticalSplit(urls: [url])
        }
      }
    )
  }

  func addViews(withTopInset topInset: CGFloat) {
    if self.neoVimView.usesCustomTabBar {
      self.addViewsWithTabBar(withTopInset: topInset)
    } else {
      self.addViewsWithoutTabBar(withTopInset: topInset)
    }
  }

  private func addViewsWithTabBar(withTopInset topInset: CGFloat) {
    guard let tabBar = self.neoVimView.tabBar else {
      self.log.error("Could not get the TabBar from NvimView!")
      self.addViewsWithoutTabBar(withTopInset: 0)
      return
    }
    let ws = self.workspace

    // FIXME: Find out why we have to add tabBar after adding ws, otherwise tabBar is not visible
    // With deployment target 10_15, adding first tabBar worked fine.
    self.window.contentView?.addSubview(ws)
    self.window.contentView?.addSubview(tabBar)

    tabBar.autoPinEdge(toSuperviewEdge: .top, withInset: topInset)
    tabBar.autoPinEdge(toSuperviewEdge: .left)
    tabBar.autoPinEdge(toSuperviewEdge: .right)

    ws.autoPinEdge(.top, to: .bottom, of: tabBar)
    ws.autoPinEdge(toSuperviewEdge: .left)
    ws.autoPinEdge(toSuperviewEdge: .right)
    ws.autoPinEdge(toSuperviewEdge: .bottom)
  }

  private func addViewsWithoutTabBar(withTopInset topInset: CGFloat) {
    let ws = self.workspace

    self.window.contentView?.addSubview(ws)
    ws.autoPinEdge(toSuperviewEdge: .top, withInset: topInset)
    ws.autoPinEdge(toSuperviewEdge: .right)
    ws.autoPinEdge(toSuperviewEdge: .bottom)
    ws.autoPinEdge(toSuperviewEdge: .left)
  }

  private func showInitError() {
    let content = UNMutableNotificationContent()
    content.title = "Error during initialization"
    content.body =
      """
      There was an error during the initialization of NeoVim. Use :messages to view the error messages.
      """
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    UNUserNotificationCenter.current().add(request)
  }

  private func show(warning: NvimView.Warning) {
    let alert = NSAlert()
    alert.addButton(withTitle: "OK")
    switch warning {
    case .cannotCloseLastTab: alert.messageText = "You cannot close the last tab."
    case .noWriteSinceLastChange: alert.messageText = "There are changes since the last write."
    }
    alert.alertStyle = .informational
    alert.beginSheetModal(for: self.window) { _ in
      Swift.print("fdsfd")
    }
  }

  func revealCurrentBufferInFileBrowser() {
    self.fileBrowser?.scrollToSourceAction(nil)
  }

  func refreshFileBrowser() {
    self.fileBrowser?.refreshAction(nil)
  }
}

// NvimViewDelegate
extension MainWindow {
  func isMenuItemKeyEquivalent(_ event: NSEvent) -> Bool {
    self.shortcutService?.isMenuItemShortcut(event) == true
  }
}
