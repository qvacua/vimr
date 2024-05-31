/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import NvimView
import RxNeovim
import RxPack
import RxSwift
import Workspace

// MARK: - NvimViewDelegate

extension MainWindow {
  // Use only when Cmd-Q'ing
  func waitTillNvimExits() {
    self.neoVimView.waitTillNvimExits()
  }

  func neoVimStopped() {
    if self.isClosing { return }
    self.prepareClosing()

    self.windowController.close()
    self.set(dirtyStatus: false)
    self.emit(self.uuidAction(for: .close))
  }

  func prepareClosing() {
    self.isClosing = true

    // If we close the window in the full screen mode, either by clicking the close button or by
    // invoking :q
    // the main thread crashes. We exit the full screen mode here as a quick and dirty hack.
    if self.window.styleMask.contains(.fullScreen) {
      self.window.toggleFullScreen(nil)
    }

    guard let cliPipePath = self.cliPipePath,
          FileManager.default.fileExists(atPath: cliPipePath)
    else {
      return
    }

    let fd = Darwin.open(cliPipePath, O_RDWR)
    guard fd != -1 else {
      return
    }

    let handle = FileHandle(fileDescriptor: fd)
    handle.closeFile()
    _ = Darwin.close(fd)
  }

  func set(title: String) {
    self.window.title = title
  }

  func set(dirtyStatus: Bool) {
    self.emit(self.uuidAction(for: .setDirtyStatus(dirtyStatus)))
  }

  func cwdChanged() {
    self.emit(self.uuidAction(for: .cd(to: self.neoVimView.cwd)))
  }

  func bufferListChanged() {
    self.neoVimView
      .allBuffers()
      .subscribe(onSuccess: { [weak self] buffers in
        guard let action = self?.uuidAction(for: .setBufferList(buffers.filter(\.isListed))) else {
          return
        }
        self?.emit(action)
      })
      .disposed(by: self.disposeBag)
  }

  func bufferWritten(_ buffer: NvimView.Buffer) {
    self.emit(self.uuidAction(for: .bufferWritten(buffer)))
  }

  func newCurrentBuffer(_ currentBuffer: NvimView.Buffer) {
    self.emit(self.uuidAction(for: .newCurrentBuffer(currentBuffer)))
  }

  func tabChanged() {
    self.neoVimView
      .currentBuffer()
      .subscribe(onSuccess: { [weak self] in
        self?.newCurrentBuffer($0)
      })
      .disposed(by: self.disposeBag)
  }

  func colorschemeChanged(to nvimTheme: NvimView.Theme) {
    self
      .updateCssColors()
      .subscribe(onSuccess: { colors in
        self.emit(
          self.uuidAction(
            for: .setTheme(Theme(from: nvimTheme, additionalColorDict: colors))
          )
        )
      }, onFailure: {
        _ in self.log.trace("oops couldn't set theme")
      })
      .disposed(by: self.disposeBag)
  }

  func guifontChanged(to font: NSFont) {
    self.emit(self.uuidAction(for: .setFont(font)))
  }

  func ipcBecameInvalid(reason: String) {
    let alert = NSAlert()
    alert.addButton(withTitle: "Close")
    alert.messageText = "Sorry, an error occurred."
    alert
      .informativeText =
      "VimR encountered an error from which it cannot recover. This window will now close.\n"
        + reason
    alert.alertStyle = .critical
    alert.beginSheetModal(for: self.window) { _ in
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

  private func updateCssColors() -> Single<[String: CellAttributes]> {
    let colorNames = [
      "Normal", // color and background-color
      "Directory", // a
      "Question", // blockquote foreground
      "CursorColumn", // code background and foreground
    ]

    typealias HlResult = [String: RxNeovimApi.Value]
    typealias ColorNameHlResultTuple = (colorName: String, hlResult: HlResult)
    typealias ColorNameObservableTuple = (colorName: String, observable: Observable<HlResult>)

    return Observable
      .from(colorNames.map { colorName -> ColorNameObservableTuple in
        (
          colorName: colorName,
          observable: self.neoVimView.api
            .nvimGetHl(
              ns_id: 0,
              opts: ["name": MessagePackValue(colorName)]
            )
            .asObservable()
        )
      })
      .flatMap { tuple -> Observable<(String, HlResult)> in
        Observable.zip(Observable.just(tuple.colorName), tuple.observable)
      }
      .reduce([ColorNameHlResultTuple]()) { (result, element: ColorNameHlResultTuple) in
        result + [element]
      }
      .map { (array: [ColorNameHlResultTuple]) in
        Dictionary(uniqueKeysWithValues: array)
          .mapValues { value in
            CellAttributes(withDict: value, with: self.neoVimView.defaultCellAttributes)
          }
      }
      .asSingle()
  }
}

// MARK: - NSWindowDelegate

extension MainWindow {
  func windowWillEnterFullScreen(_: Notification) {
    self.unthemeTitlebar(dueFullScreen: true)
  }

  func windowDidExitFullScreen(_: Notification) {
    if self.titlebarThemed {
      self.themeTitlebar(grow: true)
    }
  }

  func windowDidBecomeMain(_: Notification) {
    self
      .emit(
        self
          .uuidAction(for: .becomeKey(isFullScreen: self.window.styleMask.contains(.fullScreen)))
      )
    self.neoVimView.didBecomeMain().subscribe().disposed(by: self.disposeBag)
  }

  func windowDidResignMain(_: Notification) {
    self.neoVimView.didResignMain().subscribe().disposed(by: self.disposeBag)
  }

  func windowDidMove(_: Notification) {
    self.emit(self.uuidAction(for: .frameChanged(to: self.window.frame)))
  }

  func windowDidResize(_: Notification) {
    if self.window.styleMask.contains(.fullScreen) {
      return
    }

    self.emit(self.uuidAction(for: .frameChanged(to: self.window.frame)))
  }

  func windowShouldClose(_: NSWindow) -> Bool {
    defer { self.closeWindow = false }

    if self.neoVimView.isBlocked().syncValue() ?? false {
      let alert = NSAlert()
      alert.messageText = "Nvim is waiting for your input."
      alert.alertStyle = .informational
      alert.runModal()
      return false
    }

    if self.closeWindow {
      if self.neoVimView.hasDirtyBuffers().syncValue() == true {
        self.discardCloseActionAlert().beginSheetModal(for: self.window) { response in
          if response == .alertSecondButtonReturn {
            try? self.neoVimView.quitNeoVimWithoutSaving().wait()
          }
        }
      } else {
        try? self.neoVimView.quitNeoVimWithoutSaving().wait()
      }

      return false
    }

    guard self.neoVimView.isCurrentBufferDirty().syncValue() ?? false else {
      try? self.neoVimView.closeCurrentTab().wait()
      return false
    }

    self.discardCloseActionAlert().beginSheetModal(for: self.window) { response in
      if response == .alertSecondButtonReturn {
        try? self.neoVimView.closeCurrentTabWithoutSaving().wait()
      }
    }

    return false
  }

  private func discardCloseActionAlert() -> NSAlert {
    let alert = NSAlert()
    let cancelButton = alert.addButton(withTitle: "Cancel")
    let discardAndCloseButton = alert.addButton(withTitle: "Discard and Close")
    cancelButton.keyEquivalent = "\u{1b}"
    alert.messageText = "The current buffer has unsaved changes!"
    alert.alertStyle = .warning
    discardAndCloseButton.keyEquivalentModifierMask = .command
    discardAndCloseButton.keyEquivalent = "d"

    return alert
  }
}

// MARK: - WorkspaceDelegate

extension MainWindow {
  func resizeWillStart(workspace _: Workspace, tool _: WorkspaceTool?) {
    self.neoVimView.enterResizeMode()
  }

  func resizeDidEnd(workspace _: Workspace, tool: WorkspaceTool?) {
    self.neoVimView.exitResizeMode()

    if let workspaceTool = tool, let toolIdentifier = self.toolIdentifier(for: workspaceTool) {
      self.emit(self.uuidAction(for: .setState(for: toolIdentifier, with: workspaceTool)))
    }
  }

  func toggled(tool: WorkspaceTool) {
    if let toolIdentifier = self.toolIdentifier(for: tool) {
      self.emit(self.uuidAction(for: .setState(for: toolIdentifier, with: tool)))
    }
  }

  func moved(tool: WorkspaceTool) {
    let tools = self.workspace.orderedTools
      .compactMap { (tool: WorkspaceTool) -> (Tools, WorkspaceTool)? in
        guard let toolId = self.toolIdentifier(for: tool) else {
          return nil
        }

        return (toolId, tool)
      }

    self.emit(self.uuidAction(for: .setToolsState(tools)))
  }

  private func toolIdentifier(for tool: WorkspaceTool) -> Tools? {
    if tool == self.fileBrowserContainer {
      return .fileBrowser
    }

    if tool == self.buffersListContainer {
      return .buffersList
    }

    if tool == self.previewContainer {
      return .preview
    }

    if tool == self.htmlPreviewContainer {
      return .htmlPreview
    }

    return nil
  }
}
