/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import SwiftNeoVim
import PureLayout

class MainWindow: NSObject,
                  UiComponent,
                  NeoVimViewDelegate,
                  NSWindowDelegate,
                  NSUserInterfaceValidations,
                  WorkspaceDelegate {

  typealias StateType = State

  enum Action {

    case cd(to: URL)
    case setBufferList([NeoVimBuffer])

    case setCurrentBuffer(NeoVimBuffer)
    case setDirtyStatus(Bool)

    case becomeKey(isFullScreen: Bool)
    case frameChanged(to: CGRect)

    case scroll(to: Marked<Position>)
    case setCursor(to: Marked<Position>)

    case focus(FocusableView)

    case openQuickly

    case toggleAllTools(Bool)
    case toggleToolButtons(Bool)
    case setState(for: Tools, with: WorkspaceTool)
    case setToolsState([(Tools, WorkspaceTool)])

    case setTheme(Theme)

    case close
  }

  enum FocusableView {

    case neoVimView
    case fileBrowser
    case preview
  }

  enum Tools: String {

    static let all = Set([Tools.fileBrowser, Tools.buffersList, Tools.preview, Tools.htmlPreview])

    case fileBrowser = "com.qvacua.vimr.tools.file-browser"
    case buffersList = "com.qvacua.vimr.tools.opened-files-list"
    case preview = "com.qvacua.vimr.tools.preview"
    case htmlPreview = "com.qvacua.vimr.tools.html-preview"
  }

  enum OpenMode {

    case `default`
    case currentTab
    case newTab
    case horizontalSplit
    case verticalSplit
  }

  let uuid: String
  let emit: (UuidAction<Action>) -> Void

  let windowController: NSWindowController
  var window: NSWindow {
    return self.windowController.window!
  }

  let workspace: Workspace
  let neoVimView: NeoVimView

  let scrollDebouncer = Debouncer<Action>(interval: 0.75)
  let cursorDebouncer = Debouncer<Action>(interval: 0.75)
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

  var isClosing = false
  let cliPipePath: String?

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    self.cliPipePath = state.cliPipePath

    self.windowController = NSWindowController(windowNibName: NSNib.Name(rawValue: "MainWindow"))

    let neoVimViewConfig = NeoVimView.Config(useInteractiveZsh: state.useInteractiveZsh,
                                             cwd: state.cwd,
                                             nvimArgs: state.nvimArgs)
    self.neoVimView = NeoVimView(frame: .zero, config: neoVimViewConfig)
    self.neoVimView.configureForAutoLayout()

    self.workspace = Workspace(mainView: self.neoVimView)

    var tools: [Tools: WorkspaceTool] = [:]
    if state.activeTools[.preview] == true {
      self.preview = PreviewTool(source: source, emitter: emitter, state: state)
      let previewConfig = WorkspaceTool.Config(title: "Markdown",
                                               view: self.preview!,
                                               customMenuItems: self.preview!.menuItems)
      self.previewContainer = WorkspaceTool(previewConfig)
      self.previewContainer!.dimension = state.tools[.preview]?.dimension ?? 250
      tools[.preview] = self.previewContainer
    }

    if state.activeTools[.htmlPreview] == true {
      self.htmlPreview = HtmlPreviewTool(source: source, emitter: emitter, state: state)
      let htmlPreviewConfig = WorkspaceTool.Config(title: "HTML",
                                                   view: self.htmlPreview!,
                                                   customToolbar: self.htmlPreview!.innerCustomToolbar)
      self.htmlPreviewContainer = WorkspaceTool(htmlPreviewConfig)
      self.htmlPreviewContainer!.dimension = state.tools[.htmlPreview]?.dimension ?? 250
      tools[.htmlPreview] = self.htmlPreviewContainer
    }

    if state.activeTools[.fileBrowser] == true {
      self.fileBrowser = FileBrowser(source: source, emitter: emitter, state: state)
      let fileBrowserConfig = WorkspaceTool.Config(title: "Files",
                                                   view: self.fileBrowser!,
                                                   customToolbar: self.fileBrowser!.innerCustomToolbar,
                                                   customMenuItems: self.fileBrowser!.menuItems)
      self.fileBrowserContainer = WorkspaceTool(fileBrowserConfig)
      self.fileBrowserContainer!.dimension = state.tools[.fileBrowser]?.dimension ?? 200
      tools[.fileBrowser] = self.fileBrowserContainer
    }

    if state.activeTools[.buffersList] == true {
      self.buffersList = BuffersList(source: source, emitter: emitter, state: state)
      let buffersListConfig = WorkspaceTool.Config(title: "Buffers", view: self.buffersList!)
      self.buffersListContainer = WorkspaceTool(buffersListConfig)
      self.buffersListContainer!.dimension = state.tools[.buffersList]?.dimension ?? 200
      tools[.buffersList] = self.buffersListContainer
    }

    self.tools = tools

    super.init()

    self.defaultFont = state.appearance.font
    self.linespacing = state.appearance.linespacing
    self.usesLigatures = state.appearance.usesLigatures

    self.editorPosition = state.preview.editorPosition
    self.previewPosition = state.preview.previewPosition

    self.usesTheme = state.appearance.usesTheme

    state.orderedTools.forEach { toolId in
      guard let tool = tools[toolId] else {
        return
      }

      self.workspace.append(tool: tool, location: state.tools[toolId]?.location ?? .left)
    }

    self.tools.forEach { (toolId, toolContainer) in
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
    self.workspace.delegate = self

    self.addViews()

    self.updateNeoVimAppearance()
    self.neoVimView.delegate = self

    self.open(urls: state.urlsToOpen)

    self.window.setFrame(state.frame, display: true)
    self.window.makeFirstResponder(self.neoVimView)

    Observable
      .of(self.scrollDebouncer.observable, self.cursorDebouncer.observable)
      .merge()
      .subscribe(onNext: { [unowned self] action in
        self.emit(self.uuidAction(for: action))
      })
      .disposed(by: self.disposeBag)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.isClosing {
          return
        }

        if state.viewToBeFocused != nil, case .neoVimView = state.viewToBeFocused! {
          self.window.makeFirstResponder(self.neoVimView)
        }

        self.windowController.setDocumentEdited(state.isDirty)

        if let cwd = state.cwdToSet {
          self.neoVimView.cwd = cwd
        }

        if state.previewTool.isReverseSearchAutomatically
           && state.preview.previewPosition.hasDifferentMark(as: self.previewPosition)
           && !state.preview.ignoreNextReverse {
          self.neoVimView.cursorGo(to: state.preview.previewPosition.payload)
        } else if state.preview.forceNextReverse {
          self.neoVimView.cursorGo(to: state.preview.previewPosition.payload)
        }

        self.previewPosition = state.preview.previewPosition

        self.open(urls: state.urlsToOpen)

        if let currentBuffer = state.currentBufferToSet {
          self.neoVimView.select(buffer: currentBuffer)
        }

        let usesTheme = state.appearance.usesTheme
        let themePrefChanged = state.appearance.usesTheme != self.usesTheme
        let themeChanged = state.appearance.theme.mark != self.lastThemeMark

        if themeChanged {
          self.theme = state.appearance.theme.payload
        }

        _ = changeTheme(
          themePrefChanged: themePrefChanged, themeChanged: themeChanged, usesTheme: usesTheme,
          forTheme: {
            self.themeTitlebar(grow: !self.titlebarThemed)
            self.window.backgroundColor = state.appearance.theme.payload.background.brightening(by: 0.9)

            self.set(workspaceThemeWith: state.appearance.theme.payload)
            self.lastThemeMark = state.appearance.theme.mark
          },
          forDefaultTheme: {
            self.unthemeTitlebar(dueFullScreen: false)
            self.window.backgroundColor = .windowBackgroundColor
            self.workspace.theme = .default
          })

        self.usesTheme = state.appearance.usesTheme
        self.currentBuffer = state.currentBuffer

        if state.appearance.showsFileIcon {
          self.set(repUrl: self.currentBuffer?.url, themed: self.titlebarThemed)
        } else {
          self.set(repUrl: nil, themed: self.titlebarThemed)
        }

        if self.defaultFont != state.appearance.font
           || self.linespacing != state.appearance.linespacing
           || self.usesLigatures != state.appearance.usesLigatures {
          self.defaultFont = state.appearance.font
          self.linespacing = state.appearance.linespacing
          self.usesLigatures = state.appearance.usesLigatures

          self.updateNeoVimAppearance()
        }
      })
      .disposed(by: self.disposeBag)
  }

  func uuidAction(for action: Action) -> UuidAction<Action> {
    return UuidAction(uuid: self.uuid, action: action)
  }

  func show() {
    self.windowController.showWindow(self)
  }

  // The following should only be used when Cmd-Q'ing
  func quitNeoVimWithoutSaving() {
    self.neoVimView.quitNeoVimWithoutSaving()
  }

  @IBAction func debug2(_: Any?) {
    var theme = Theme.default
    theme.foreground = .blue
    theme.background = .yellow
    theme.highlightForeground = .orange
    theme.highlightBackground = .red
    self.emit(uuidAction(for: .setTheme(theme)))
  }

  fileprivate let disposeBag = DisposeBag()

  fileprivate var currentBuffer: NeoVimBuffer?

  fileprivate var defaultFont = NeoVimView.defaultFont
  fileprivate var linespacing = NeoVimView.defaultLinespacing
  fileprivate var usesLigatures = false

  fileprivate var previewPosition = Marked(Position.beginning)

  fileprivate var preview: PreviewTool?
  fileprivate var htmlPreview: HtmlPreviewTool?
  fileprivate var fileBrowser: FileBrowser?
  fileprivate var buffersList: BuffersList?

  fileprivate var usesTheme = true
  fileprivate var lastThemeMark = Token()

  fileprivate func updateNeoVimAppearance() {
    self.neoVimView.font = self.defaultFont
    self.neoVimView.linespacing = self.linespacing
    self.neoVimView.usesLigatures = self.usesLigatures
  }

  fileprivate func set(workspaceThemeWith theme: Theme) {
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

  fileprivate func open(urls: [URL: OpenMode]) {
    // If we don't call the following in the next tick, only half of the existing swap file warning is displayed.
    // Dunno why...
    DispatchQueue.main.async {
      urls.forEach { (url: URL, openMode: OpenMode) in
        switch openMode {

        case .default:
          self.neoVimView.open(urls: [url])

        case .currentTab:
          self.neoVimView.openInCurrentTab(url: url)

        case .newTab:
          self.neoVimView.openInNewTab(urls: [url])

        case .horizontalSplit:
          self.neoVimView.openInHorizontalSplit(urls: [url])

        case .verticalSplit:
          self.neoVimView.openInVerticalSplit(urls: [url])

        }
      }
    }
  }

  fileprivate func addViews() {
    self.window.contentView?.addSubview(self.workspace)
    self.workspace.autoPinEdgesToSuperviewEdges()
  }
}
