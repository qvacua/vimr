/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import NvimApi
import NvimView
import Workspace

// MARK: - NvimViewDelegate

extension MainWindow {
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

  func bufferListChanged() async {
    let bufs = await self.neoVimView.allBuffers() ?? []
    let action = self.uuidAction(for: .setBufferList(bufs.filter(\.isListed)))
    self.emit(action)
  }

  func bufferWritten(_ buffer: NvimView.Buffer) {
    self.emit(self.uuidAction(for: .bufferWritten(buffer)))
  }

  func newCurrentBuffer(_ currentBuffer: NvimView.Buffer) {
    self.emit(self.uuidAction(for: .newCurrentBuffer(currentBuffer)))
  }

  func tabChanged() async {
    if let curBuf = await self.neoVimView.currentBuffer() {
      self.newCurrentBuffer(curBuf)
    }
  }

  func colorschemeChanged(to nvimTheme: NvimView.Theme) {
    self.log.debugAny("Theme changed delegate method: \(nvimTheme)")
    if let colors = self.updatedCssColors() {
      self.emit(
        self.uuidAction(for: .setTheme(Theme(from: nvimTheme, additionalColorDict: colors)))
      )
    } else {
      self.log.debug("oops couldn't set theme")
    }
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
    self.scrollThrottler.call(.scroll(to: Marked(self.neoVimView.currentPosition)))
  }

  func cursor(to position: Position) {
    if position == self.editorPosition.payload {
      return
    }

    self.editorPosition = Marked(position)
    self.cursorThrottler.call(.setCursor(to: self.editorPosition))
  }

  private func updatedCssColors() -> [String: CellAttributes]? {
    let colorNames = [
      "Normal", // color and background-color
      "Directory", // a
      "Question", // blockquote foreground
      "CursorColumn", // code background and foreground
    ]

    let map: [String: CellAttributes] = colorNames.reduce(into: [:]) { dict, colorName in
      let result = self.neoVimView.apiSync.nvimGetHl(
        ns_id: 0,
        opts: ["name": MessagePackValue(colorName)]
      )
      Swift.print("############## \(result)")

      guard let name = try? result.get() else { return }

      dict[colorName] = CellAttributes(withDict: name, with: self.neoVimView.defaultCellAttributes)
    }.compactMapValues { $0 }

    if map.count == colorNames.count { return map }
    else { return nil }
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

    Task {
      await self.neoVimView.didBecomeMain()
    }
  }

  func windowDidResignMain(_: Notification) {
    Task {
      await self.neoVimView.didResignMain()
    }
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

    Task {
      if await self.neoVimView.isBlocked() {
        let alert = NSAlert()
        alert.messageText = "Nvim is waiting for your input."
        alert.alertStyle = .informational
        alert.runModal()
        return
      }

      if self.closeWindow {
        if await self.neoVimView.hasDirtyBuffers() {
          self.discardCloseActionAlert().beginSheetModal(for: self.window) { response in
            if response == .alertSecondButtonReturn {
              Task {
                await self.neoVimView.quitNeoVimWithoutSaving()
              }
            }
          }
        } else {
          await self.neoVimView.quitNeoVimWithoutSaving()
        }

        return
      }

      guard await self.neoVimView.isCurrentBufferDirty() else {
        await self.neoVimView.closeCurrentTab()
        return
      }

      self.discardCloseActionAlert().beginSheetModal(for: self.window) { response in
        if response == .alertSecondButtonReturn {
          Task {
            await self.neoVimView.closeCurrentTabWithoutSaving()
          }
        }
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

    if let tool, let toolIdentifier = self.toolIdentifier(for: tool) {
      self.emit(self.uuidAction(for: .setState(
        for: toolIdentifier,
        with: .init(location: tool.location, dimension: tool.dimension, open: tool.isSelected)
      )))
    }
  }

  func toggled(tool: WorkspaceTool) {
    if let toolIdentifier = self.toolIdentifier(for: tool) {
      self.emit(self.uuidAction(for: .setState(
        for: toolIdentifier,
        with: .init(location: tool.location, dimension: tool.dimension, open: tool.isSelected)
      )))
    }
  }

  func moved(tool: WorkspaceTool) {
    let tools = self.workspace.orderedTools
      .compactMap { (tool: WorkspaceTool) -> (Tools, WorkspaceToolState)? in
        guard let toolId = self.toolIdentifier(for: tool) else {
          return nil
        }

        return (
          toolId,
          .init(location: tool.location, dimension: tool.dimension, open: tool.isSelected)
        )
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
