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
                  NSWindowDelegate {

  typealias StateType = State

  enum Action {

    case open(Set<Token>)

    case cd(to: URL)
    case setBufferList([NeoVimBuffer])

    case setCurrentBuffer(NeoVimBuffer)

    case becomeKey

    case scroll(to: Marked<Position>)
    case setCursor(to: Marked<Position>)

    case openQuickly

    case close
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

    self.editorPosition = state.preview.editorPosition
    self.previewPosition = state.preview.previewPosition

    self.neoVimView = NeoVimView(frame: CGRect.zero,
                                 config: NeoVimView.Config(useInteractiveZsh: state.isUseInteractiveZsh))
    self.neoVimView.configureForAutoLayout()

    self.workspace = Workspace(mainView: self.neoVimView)
    self.preview = PreviewTool(source: source, emitter: emitter, state: state)
    self.fileBrowser = FileBrowser(source: source, emitter: emitter, state: state)

    self.windowController = NSWindowController(windowNibName: "MainWindow")

    super.init()

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
          if state.isClosed {
            return
          }

          if state.previewTool.isReverseSearchAutomatically
             && state.preview.previewPosition.hasDifferentMark(as: self.previewPosition) {
            self.neoVimView.cursorGo(to: state.preview.previewPosition.payload)
          } else if state.preview.forceNextReverse {
            self.neoVimView.cursorGo(to: state.preview.previewPosition.payload)
          }

          self.previewPosition = state.preview.previewPosition

          self.marksForOpenedUrls.subtracting(state.urlsToOpen.map { $0.mark }).forEach {
            self.marksForOpenedUrls.remove($0)
          }

          self.open(markedUrls: state.urlsToOpen)
        },
        onCompleted: {
          self.windowController.close()
        })
      .addDisposableTo(self.disposeBag)

    let neoVimView = self.neoVimView
    neoVimView.delegate = self
    neoVimView.font = state.font
    neoVimView.linespacing = state.linespacing
    neoVimView.usesLigatures = state.isUseLigatures
    if neoVimView.cwd != state.cwd {
      self.neoVimView.cwd = state.cwd
    }

    self.open(markedUrls: state.urlsToOpen)

    self.window.makeFirstResponder(neoVimView)
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

  fileprivate let windowController: NSWindowController
  fileprivate var window: NSWindow { return self.windowController.window! }

  fileprivate let workspace: Workspace
  fileprivate let neoVimView: NeoVimView

  fileprivate let preview: PreviewTool
  fileprivate var editorPosition: Marked<Position>
  fileprivate var previewPosition: Marked<Position>

  fileprivate let fileBrowser: FileBrowser

  fileprivate let scrollDebouncer = Debouncer<Action>(interval: 0.75)
  fileprivate let cursorDebouncer = Debouncer<Action>(interval: 0.75)

  fileprivate var marksForOpenedUrls = Set<Token>()

  fileprivate func uuidAction(for action: Action) -> UuidAction<Action> {
    return UuidAction(uuid: self.uuid, action: action)
  }

  fileprivate func open(markedUrls: [Marked<[URL: OpenMode]>]) {
    let markedUrlsToOpen = markedUrls.filter { !self.marksForOpenedUrls.contains($0.mark) }

    markedUrls.map { $0.mark }.forEach {
      self.marksForOpenedUrls.insert($0)
    }

    guard markedUrlsToOpen.count > 0 else {
      return
    }

    // If we don't call the following in the next tick, only half of the existing swap file warning is displayed.
    // Dunno why...
    DispatchUtils.gui {
      markedUrlsToOpen.forEach { marked in
        marked.payload.forEach { (url: URL, openMode: OpenMode) in
          switch openMode {

          case .default:
            self.neoVimView.open(urls: [url])

          case .currentTab:
            self.neoVimView.openInCurrentTab(url: url)

          case .newTab:
            NSLog("state: \(markedUrls.map { $0.mark })")
            NSLog("self: \(self.marksForOpenedUrls)")
            NSLog("opening!!!!!!!!!!!!!!!!!!!!!! \(marked.mark)")
            self.neoVimView.openInNewTab(urls: [url])

          case .horizontalSplit:
            self.neoVimView.openInHorizontalSplit(urls: [url])

          case .verticalSplit:
            self.neoVimView.openInVerticalSplit(urls: [url])

          }
        }
      }

      // not good, but we need it because we don't want to re-build the whole tab/window/buffer state of neovim in
      // MainWindow.State
      self.emitter.emit(self.uuidAction(for: Action.open(Set(markedUrls.map { $0.mark }))))
    }
  }

  fileprivate func setupTools() {
    let previewConfig = WorkspaceTool.Config(title: "Preview",
                                             view: self.preview,
                                             customMenuItems: self.preview.menuItems)
    let previewContainer = WorkspaceTool(previewConfig)
    previewContainer.dimension = 300

    let fileBrowserConfig = WorkspaceTool.Config(title: "Files",
                                                 view: self.fileBrowser,
                                                 customToolbar: self.fileBrowser.innerCustomToolbar,
                                                 customMenuItems: self.fileBrowser.menuItems)
    let fileBrowserContainer = WorkspaceTool(fileBrowserConfig)
    fileBrowserContainer.dimension = 200

    self.workspace.append(tool: previewContainer, location: .right)
    self.workspace.append(tool: fileBrowserContainer, location: .left)

    fileBrowserContainer.toggle()
  }

  fileprivate func addViews() {
    let contentView = self.window.contentView!

    contentView.addSubview(self.workspace)
    self.setupTools()

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
    self.windowController.setDocumentEdited(dirtyStatus)
  }

  func cwdChanged() {
    NSLog("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    self.emitter.emit(self.uuidAction(for: .cd(to: self.neoVimView.cwd)))
  }

  func bufferListChanged() {
    let buffers = self.neoVimView.allBuffers()
    self.emitter.emit(self.uuidAction(for: .setBufferList(buffers)))
  }

  func currentBufferChanged(_ currentBuffer: NeoVimBuffer) {
    self.emitter.emit(self.uuidAction(for: .setCurrentBuffer(currentBuffer)))
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

// MARK: - IBActions
extension MainWindow {

  @IBAction func openQuickly(_ sender: Any?) {
    self.emitter.emit(self.uuidAction(for: .openQuickly))
  }
}
