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

    case becomeKey

    case scroll(to: Marked<Position>)
    case setCursor(to: Marked<Position>)

    case focus(FocusableView)

    case openQuickly

    case toggleAllTools(Bool)
    case toggleToolButtons(Bool)
    case setState(for: Tools, with: WorkspaceTool)
    case setToolsState([(Tools, WorkspaceTool)])

    case close
  }

  enum FocusableView {

    case neoVimView
    case fileBrowser
    case preview
  }

  enum Tools: String {

    static let all = Set([Tools.fileBrowser, Tools.openedFilesList, Tools.preview, Tools.htmlPreview])

    case fileBrowser = "com.qvacua.vimr.tools.file-browser"
    case openedFilesList = "com.qvacua.vimr.tools.opened-files-list"
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

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.uuid = state.uuid
    self.emitter = emitter

    self.defaultFont = state.appearance.font
    self.linespacing = state.appearance.linespacing
    self.usesLigatures = state.appearance.usesLigatures

    self.editorPosition = state.preview.editorPosition
    self.previewPosition = state.preview.previewPosition

    self.neoVimView = NeoVimView(frame: CGRect.zero,
                                 config: NeoVimView.Config(useInteractiveZsh: state.useInteractiveZsh))
    self.neoVimView.configureForAutoLayout()

    let workspace = Workspace(mainView: self.neoVimView)
    self.workspace = workspace
    self.preview = PreviewTool(source: source, emitter: emitter, state: state)
    self.fileBrowser = FileBrowser(source: source, emitter: emitter, state: state)
    self.openedFileList = OpenedFileList(source: source, emitter: emitter, state: state)
    self.htmlPreview = HtmlPreviewTool(source: source, emitter: emitter, state: state)

    if !state.isToolButtonsVisible {
      self.workspace.toggleToolButtons()
    }

    self.windowController = NSWindowController(windowNibName: "MainWindow")

    let previewConfig = WorkspaceTool.Config(title: "Preview",
                                             view: self.preview,
                                             customMenuItems: self.preview.menuItems)
    self.previewContainer = WorkspaceTool(previewConfig)
    self.previewContainer.dimension = state.tools[.preview]?.dimension ?? 250

    let htmlPreviewConfig = WorkspaceTool.Config(title: "HTML Preview",
                                                 view: self.htmlPreview,
                                                 customToolbar: self.htmlPreview.innerCustomToolbar)
    self.htmlPreviewContainer = WorkspaceTool(htmlPreviewConfig)
    self.htmlPreviewContainer.dimension = state.tools[.htmlPreview]?.dimension ?? 250

    let fileBrowserConfig = WorkspaceTool.Config(title: "Files",
                                                 view: self.fileBrowser,
                                                 customToolbar: self.fileBrowser.innerCustomToolbar,
                                                 customMenuItems: self.fileBrowser.menuItems)
    self.fileBrowserContainer = WorkspaceTool(fileBrowserConfig)
    self.fileBrowserContainer.dimension = state.tools[.fileBrowser]?.dimension ?? 200

    let openedFileListConfig = WorkspaceTool.Config(title: "Buffers", view: self.openedFileList)
    self.openedFileListContainer = WorkspaceTool(openedFileListConfig)
    self.openedFileListContainer.dimension = state.tools[.openedFilesList]?.dimension ?? 200

    let tools: [Tools: WorkspaceTool] = [
      .fileBrowser: self.fileBrowserContainer,
      .openedFilesList: self.openedFileListContainer,
      .preview: self.previewContainer,
      .htmlPreview: self.htmlPreviewContainer,
    ]

    self.tools = tools
    state.orderedTools.forEach { toolId in
      guard let tool = tools[toolId] else {
        return
      }

      workspace.append(tool: tool, location: state.tools[toolId]?.location ?? .left)
    }

    super.init()

    self.tools.forEach { (toolId, toolContainer) in
      if state.tools[toolId]?.open == true {
        toolContainer.toggle()
      }
    }

    self.workspace.delegate = self

    Observable
      .of(self.scrollDebouncer.observable, self.cursorDebouncer.observable)
      .merge()
      .subscribe(onNext: { [unowned self] action in
        self.emitter.emit(self.uuidAction(for: action))
      })
      .addDisposableTo(self.disposeBag)

    self.addViews()

    self.windowController.window?.delegate = self

    source
      .observeOn(MainScheduler.instance)
      .subscribe(
        onNext: { [unowned self] state in
          if state.close && !self.isClosing {
            self.closeAllNeoVimWindowsWithoutSaving()
            self.isClosing = true
            return
          }

          if state.viewToBeFocused != nil, case .neoVimView = state.viewToBeFocused! {
            self.window.makeFirstResponder(self.neoVimView)
          }

          self.windowController.setDocumentEdited(state.isDirty)

          if self.neoVimView.cwd != state.cwd {
            self.neoVimView.cwd = state.cwd
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

          if self.currentBuffer != state.currentBuffer {
            self.currentBuffer = state.currentBuffer
            if let currentBuffer = self.currentBuffer {
              self.neoVimView.select(buffer: currentBuffer)
            }
          }

          if self.defaultFont != state.appearance.font
             || self.linespacing != state.appearance.linespacing
             || self.usesLigatures != state.appearance.usesLigatures {
            self.defaultFont = state.appearance.font
            self.linespacing = state.appearance.linespacing
            self.usesLigatures = state.appearance.usesLigatures

            self.updateNeoVimAppearance()
          }
        },
        onCompleted: {
          self.windowController.close()
        })
      .addDisposableTo(self.disposeBag)

    self.updateNeoVimAppearance()
    self.neoVimView.delegate = self
    if self.neoVimView.cwd != state.cwd {
      self.neoVimView.cwd = state.cwd
    }

    self.open(urls: state.urlsToOpen)

    self.window.makeFirstResponder(self.neoVimView)
  }

  func show() {
    self.windowController.showWindow(self)
  }

  func closeAllNeoVimWindowsWithoutSaving() {
    self.neoVimView.closeAllWindowsWithoutSaving()
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let uuid: String

  fileprivate var currentBuffer: NeoVimBuffer?

  fileprivate let windowController: NSWindowController
  fileprivate var window: NSWindow { return self.windowController.window! }

  fileprivate var defaultFont: NSFont
  fileprivate var linespacing: CGFloat
  fileprivate var usesLigatures: Bool

  fileprivate let fontManager = NSFontManager.shared()

  fileprivate let workspace: Workspace
  fileprivate let neoVimView: NeoVimView

  fileprivate let previewContainer: WorkspaceTool
  fileprivate let fileBrowserContainer: WorkspaceTool
  fileprivate let openedFileListContainer: WorkspaceTool
  fileprivate let htmlPreviewContainer: WorkspaceTool

  fileprivate var editorPosition: Marked<Position>
  fileprivate var previewPosition: Marked<Position>

  fileprivate let preview: PreviewTool
  fileprivate let htmlPreview: HtmlPreviewTool
  fileprivate let fileBrowser: FileBrowser
  fileprivate let openedFileList: OpenedFileList

  fileprivate let tools: [Tools: WorkspaceTool]

  fileprivate let scrollDebouncer = Debouncer<Action>(interval: 0.75)
  fileprivate let cursorDebouncer = Debouncer<Action>(interval: 0.75)

  fileprivate var isClosing = false

  fileprivate func updateNeoVimAppearance() {
    self.neoVimView.font = self.defaultFont
    self.neoVimView.linespacing = self.linespacing
    self.neoVimView.usesLigatures = self.usesLigatures
  }

  fileprivate func uuidAction(for action: Action) -> UuidAction<Action> {
    return UuidAction(uuid: self.uuid, action: action)
  }

  fileprivate func open(urls: [URL: OpenMode]) {
    // If we don't call the following in the next tick, only half of the existing swap file warning is displayed.
    // Dunno why...
    DispatchUtils.gui {
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
    let contentView = self.window.contentView!

    contentView.addSubview(self.workspace)

    self.workspace.autoPinEdgesToSuperviewEdges()
  }
}

// MARK: - NeoVimViewDelegate

extension MainWindow {

  func neoVimStopped() {
    self.emitter.emit(self.uuidAction(for: .close))
  }

  func set(title: String) {
    self.window.title = title
  }

  func set(dirtyStatus: Bool) {
    self.emitter.emit(self.uuidAction(for: .setDirtyStatus(dirtyStatus)))
  }

  func cwdChanged() {
    self.emitter.emit(self.uuidAction(for: .cd(to: self.neoVimView.cwd)))
  }

  func bufferListChanged() {
    let buffers = self.neoVimView.allBuffers()
    self.emitter.emit(self.uuidAction(for: .setBufferList(buffers)))
  }

  func currentBufferChanged(_ currentBuffer: NeoVimBuffer) {
    self.emitter.emit(self.uuidAction(for: .setCurrentBuffer(currentBuffer)))
    self.currentBuffer = currentBuffer
  }

  func tabChanged() {
    guard let currentBuffer = self.neoVimView.currentBuffer() else {
      return
    }

    self.currentBufferChanged(currentBuffer)
  }

  func ipcBecameInvalid(reason: String) {
    let alert = NSAlert()
    alert.addButton(withTitle: "Close")
    alert.messageText = "Sorry, an error occurred."
    alert.informativeText = "VimR encountered an error from which it cannot recover. This window will now close.\n"
                            + reason
    alert.alertStyle = .critical
    alert.beginSheetModal(for: self.window) { response in
      self.windowController.close()
    }
  }

  func scroll() {
    self.scrollDebouncer.call(.scroll(to: Marked(self.neoVimView.currentPosition)))
  }

  func cursor(to position: Position) {
    if position == self.editorPosition.payload {
      return
    }

    self.editorPosition = Marked(position)
    self.cursorDebouncer.call(.setCursor(to: self.editorPosition))
  }
}

// MARK: - NSWindowDelegate

extension MainWindow {

  func windowDidBecomeKey(_: Notification) {
    self.emitter.emit(self.uuidAction(for: .becomeKey))
  }

  func windowShouldClose(_: Any) -> Bool {
    guard self.neoVimView.isCurrentBufferDirty() else {
      self.neoVimView.closeCurrentTab()
      return false
    }

    let alert = NSAlert()
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Discard and Close")
    alert.messageText = "The current buffer has unsaved changes!"
    alert.alertStyle = .warning
    alert.beginSheetModal(for: self.window, completionHandler: { response in
      if response == NSAlertSecondButtonReturn {
        self.neoVimView.closeCurrentTabWithoutSaving()
      }
    })

    return false
  }
}

// MARK: - File Menu Item Actions

extension MainWindow {

  @IBAction func newTab(_ sender: Any?) {
    self.neoVimView.newTab()
  }

  @IBAction func openDocument(_ sender: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.beginSheetModal(for: self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }

      let urls = panel.urls
      if self.neoVimView.allBuffers().count == 1 {
        let isTransient = self.neoVimView.allBuffers().first?.isTransient ?? false
        if isTransient {
          self.neoVimView.cwd = FileUtils.commonParent(of: urls)
        }
      }
      self.neoVimView.open(urls: urls)
    }
  }

  @IBAction func openQuickly(_ sender: Any?) {
    self.emitter.emit(self.uuidAction(for: .openQuickly))
  }

  @IBAction func saveDocument(_ sender: Any?) {
    guard let curBuf = self.neoVimView.currentBuffer() else {
      return
    }

    if curBuf.url == nil {
      self.savePanelSheet { self.neoVimView.saveCurrentTab(url: $0) }
      return
    }

    self.neoVimView.saveCurrentTab()
  }

  @IBAction func saveDocumentAs(_ sender: Any?) {
    if self.neoVimView.currentBuffer() == nil {
      return
    }

    self.savePanelSheet { url in
      self.neoVimView.saveCurrentTab(url: url)

      if self.neoVimView.isCurrentBufferDirty() {
        self.neoVimView.openInNewTab(urls: [url])
      } else {
        self.neoVimView.openInCurrentTab(url: url)
      }
    }
  }

  fileprivate func savePanelSheet(action: @escaping (URL) -> Void) {
    let panel = NSSavePanel()
    panel.beginSheetModal(for: self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }

      let showAlert: () -> Void = {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = "Invalid File Name"
        alert.informativeText = "The file name you have entered cannot be used. Please use a different name."
        alert.alertStyle = .warning

        alert.runModal()
      }

      guard let url = panel.url else {
        showAlert()
        return
      }

      action(url)
    }
  }
}

// MARK: - Font Menu Item Actions

extension MainWindow {

  @IBAction func resetFontSize(_ sender: Any?) {
    self.neoVimView.font = self.defaultFont
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: min(curFont.pointSize + 1, NeoVimView.maxFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: max(curFont.pointSize - 1, NeoVimView.minFontSize))
    self.neoVimView.font = font
  }
}

// MARK: - Tools Menu Item Actions

extension MainWindow {

  @IBAction func toggleAllTools(_ sender: Any?) {
    self.workspace.toggleAllTools()
    self.focusNeoVimView(self)

    self.emitter.emit(self.uuidAction(for: .toggleAllTools(self.workspace.isAllToolsVisible)))
  }

  @IBAction func toggleToolButtons(_ sender: Any?) {
    self.workspace.toggleToolButtons()
    self.emitter.emit(self.uuidAction(for: .toggleToolButtons(self.workspace.isToolButtonsVisible)))
  }

  @IBAction func toggleFileBrowser(_ sender: Any?) {
    let fileBrowser = self.fileBrowserContainer

    if fileBrowser.isSelected {
      if fileBrowser.view.isFirstResponder {
        fileBrowser.toggle()
        self.focusNeoVimView(self)
      } else {
        self.emitter.emit(self.uuidAction(for: .focus(.fileBrowser)))
      }

      return
    }

    fileBrowser.toggle()
    self.emitter.emit(self.uuidAction(for: .focus(.fileBrowser)))
  }

  @IBAction func focusNeoVimView(_: Any?) {
//    self.window.makeFirstResponder(self.neoVimView)
    self.emitter.emit(self.uuidAction(for: .focus(.neoVimView)))
  }
}

// MARK: - WorkspaceDelegate

extension MainWindow {

  func resizeWillStart(workspace: Workspace, tool: WorkspaceTool?) {
    self.neoVimView.enterResizeMode()
  }

  func resizeDidEnd(workspace: Workspace, tool: WorkspaceTool?) {
    self.neoVimView.exitResizeMode()

    if let workspaceTool = tool, let toolIdentifier = self.toolIdentifier(for: workspaceTool) {
      self.emitter.emit(self.uuidAction(for: .setState(for: toolIdentifier, with: workspaceTool)))
    }
  }

  func toggled(tool: WorkspaceTool) {
    if let toolIdentifier = self.toolIdentifier(for: tool) {
      self.emitter.emit(self.uuidAction(for: .setState(for: toolIdentifier, with: tool)))
    }
  }

  func moved(tool: WorkspaceTool) {
    let tools = self.workspace.orderedTools.flatMap { (tool: WorkspaceTool) -> (Tools, WorkspaceTool)? in
      guard let toolId = self.toolIdentifier(for: tool) else {
        return nil
      }

      return (toolId, tool)
    }

    self.emitter.emit(self.uuidAction(for: .setToolsState(tools)))
  }

  fileprivate func toolIdentifier(for tool: WorkspaceTool) -> Tools? {
    switch tool {

    case self.fileBrowserContainer:
      return .fileBrowser

    case self.openedFileListContainer:
      return .openedFilesList

    case self.previewContainer:
      return .preview

    case self.htmlPreviewContainer:
      return .htmlPreview

    default:
      return nil

    }
  }
}

// MARK: - NSUserInterfaceValidationsProtocol

extension MainWindow {

  public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let canSave = self.neoVimView.currentBuffer() != nil
    let canSaveAs = canSave
    let canOpen = canSave
    let canOpenQuickly = canSave
    let canFocusNeoVimView = self.window.firstResponder != self.neoVimView

    guard let action = item.action else {
      return true
    }

    switch action {
    case #selector(focusNeoVimView(_:)):
      return canFocusNeoVimView

    case #selector(openDocument(_:)):
      return canOpen

    case #selector(openQuickly(_:)):
      return canOpenQuickly

    case #selector(saveDocument(_:)):
      return canSave

    case #selector(saveDocumentAs(_:)):
      return canSaveAs

    default:
      return true
    }
  }
}
