//
// Created by Tae Won Ha on 1/16/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Cocoa
import RxSwift
import SwiftNeoVim
import PureLayout

protocol UiComponent {

  associatedtype StateType

  init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType)
}

class MainWindow: NSObject,
                  UiComponent,
                  NeoVimViewDelegate,
                  NSWindowDelegate {

  typealias StateType = State

  enum Action {

    case cd(to: URL)
    case setBufferList([NeoVimBuffer])

    case becomeKey

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

    self.neoVimView = NeoVimView(frame: CGRect.zero,
                                 config: NeoVimView.Config(useInteractiveZsh: state.isUseInteractiveZsh))
    self.neoVimView.configureForAutoLayout()

    self.workspace = Workspace(mainView: self.neoVimView)

    self.windowController = NSWindowController(windowNibName: "MainWindow")

    super.init()
    self.addViews()

    self.windowController.window?.delegate = self

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
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

    // If we don't call the following in the next tick, only half of the existing swap file warning is displayed.
    // Dunno why...
    DispatchUtils.gui {
      state.urlsToOpen.forEach { (url: URL, openMode: OpenMode) in
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

    self.window.makeFirstResponder(neoVimView)
  }

  func show() {
    self.windowController.showWindow(self)
  }

  fileprivate func addViews() {
    let contentView = self.window.contentView!

    contentView.addSubview(self.workspace)

    self.workspace.autoPinEdgesToSuperviewEdges()
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let uuid: String

  fileprivate let windowController: NSWindowController
  fileprivate var window: NSWindow { return self.windowController.window! }

  fileprivate let workspace: Workspace
  fileprivate let neoVimView: NeoVimView
}

// MARK: - NeoVimViewDelegate
extension MainWindow {

  func neoVimStopped() {
    self.windowController.close()
  }

  func set(title: String) {
    self.window.title = title
  }

  func set(dirtyStatus: Bool) {
    self.windowController.setDocumentEdited(dirtyStatus)
  }

  func cwdChanged() {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.cd(to: self.neoVimView.cwd)))
  }

  func bufferListChanged() {
    let buffers = self.neoVimView.allBuffers()
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.setBufferList(buffers)))
  }

  func currentBufferChanged(_ currentBuffer: NeoVimBuffer) {
//    self.publish(event: MainWindowAction.currentBufferChanged(mainWindow: self, buffer: currentBuffer))
  }

  func tabChanged() {
//    guard let currentBuffer = self.neoVimView.currentBuffer() else {
//      return
//    }
//
//    self.publish(event: MainWindowAction.currentBufferChanged(mainWindow: self, buffer: currentBuffer))
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
//    self.scrollFlow.publish(event: ScrollAction.scroll(to: self.neoVimView.currentPosition))
  }

  func cursor(to position: Position) {
//    self.scrollFlow.publish(event: ScrollAction.cursor(to: self.neoVimView.currentPosition))
  }
}

// MARK: - NSWindowDelegate
extension MainWindow {

  func windowDidBecomeKey(_: Notification) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.becomeKey))
  }

  func windowWillClose(_: Notification) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.close))
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
