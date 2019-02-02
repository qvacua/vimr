/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

// MARK: - NvimViewDelegate
extension MainWindow {

  func neoVimStopped() {
    if self.isClosing {
      return
    }

    self.isClosing = true

    // If we close the window in the full screen mode, either by clicking the close button or by invoking :q
    // the main thread crashes. We exit the full screen mode here as a quick and dirty hack.
    if self.window.styleMask.contains(.fullScreen) {
      self.window.toggleFullScreen(nil)
    }

    self.windowController.close()
    self.set(dirtyStatus: false)
    self.emit(self.uuidAction(for: .close))

    guard let cliPipePath = self.cliPipePath, FileManager.default.fileExists(atPath: cliPipePath) else {
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
    self.set(repUrl: self.window.representedURL, themed: self.titlebarThemed)
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
      .value(onSuccess: { buffers in
        self.emit(self.uuidAction(for: .setBufferList(buffers.filter { $0.isListed })))
      })
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
      .value(onSuccess: {
        self.newCurrentBuffer($0)
      })
  }

  func colorschemeChanged(to neoVimTheme: NvimView.Theme) {
    self.emit(uuidAction(for: .setTheme(Theme(neoVimTheme))))
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

  func windowWillEnterFullScreen(_: Notification) {
    self.unthemeTitlebar(dueFullScreen: true)
  }

  func windowDidExitFullScreen(_: Notification) {
    if self.titlebarThemed {
      self.themeTitlebar(grow: true)
    }
  }

  func windowDidBecomeMain(_ notification: Notification) {
    self.emit(self.uuidAction(for: .becomeKey(isFullScreen: self.window.styleMask.contains(.fullScreen))))
    self.neoVimView.didBecomeMain().trigger()
  }

  func windowDidResignMain(_ notification: Notification) {
    self.neoVimView.didResignMain().trigger()
  }

  func windowDidMove(_ notification: Notification) {
    self.emit(self.uuidAction(for: .frameChanged(to: self.window.frame)))
  }

  func windowDidResize(_ notification: Notification) {
    if self.window.styleMask.contains(.fullScreen) {
      return
    }

    self.emit(self.uuidAction(for: .frameChanged(to: self.window.frame)))
  }

  func windowShouldClose(_: NSWindow) -> Bool {
    guard (self.neoVimView.isCurrentBufferDirty().syncValue() ?? false) else {
      try? self.neoVimView.closeCurrentTab().wait()
      return false
    }

    let alert = NSAlert()
    alert.addButton(withTitle: "Cancel")
    let discardAndCloseButton = alert.addButton(withTitle: "Discard and Close")
    alert.messageText = "The current buffer has unsaved changes!"
    alert.alertStyle = .warning
    discardAndCloseButton.keyEquivalentModifierMask = .command
    discardAndCloseButton.keyEquivalent = "d"
    alert.beginSheetModal(for: self.window, completionHandler: { response in
      if response == .alertSecondButtonReturn {
        try? self.neoVimView.closeCurrentTabWithoutSaving().wait()
      }
    })

    return false
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
      self.emit(self.uuidAction(for: .setState(for: toolIdentifier, with: workspaceTool)))
    }
  }

  func toggled(tool: WorkspaceTool) {
    if let toolIdentifier = self.toolIdentifier(for: tool) {
      self.emit(self.uuidAction(for: .setState(for: toolIdentifier, with: tool)))
    }
  }

  func moved(tool: WorkspaceTool) {
    let tools = self.workspace.orderedTools.compactMap { (tool: WorkspaceTool) -> (Tools, WorkspaceTool)? in
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
