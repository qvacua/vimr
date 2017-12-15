/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack

extension NvimView {

  public func enterResizeMode() {
    self.currentlyResizing = true
    self.needsDisplay = true
  }

  public func exitResizeMode() {
    self.currentlyResizing = false
    self.needsDisplay = true
    self.resizeNeoVimUi(to: self.bounds.size)
  }

  /**
   - returns: nil when for exampls a quickfix panel is open.
   */
  public func currentBuffer() -> NvimView.Buffer? {
    guard let buf = self.nvim.getCurrentBuf().value else {
      return nil
    }

    return self.neoVimBuffer(for: buf, currentBuffer: buf)
  }

  public func allBuffers() -> [NvimView.Buffer] {
    let curBuf = self.nvim.getCurrentBuf().value
    return self.nvim.listBufs()
             .value?
             .flatMap { self.neoVimBuffer(for: $0, currentBuffer: curBuf) } ?? []
  }

  public func isCurrentBufferDirty() -> Bool {
    return self.currentBuffer()?.isDirty ?? false
  }

  public func allTabs() -> [NvimView.Tabpage] {
    let curBuf = self.nvim.getCurrentBuf().value
    let curTab = self.nvim.getCurrentTabpage().value

    return self.nvim.listTabpages()
             .value?
             .flatMap { self.neoVimTab(for: $0, currentTabpage: curTab, currentBuffer: curBuf) } ?? []
  }

  public func newTab() {
    self.nvim.command(command: "tabe", expectsReturnValue: false)
  }

  public func `open`(urls: [URL]) {
    let tabs = self.allTabs()
    let buffers = tabs.map { $0.windows }.flatMap { $0 }.map { $0.buffer }
    let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

    urls.enumerated().forEach { (idx, url) in
      if buffers.filter({ $0.url == url }).first != nil {
        for window in tabs.map({ $0.windows }).flatMap({ $0 }) {
          if window.buffer.url == url {
            self.nvim.setCurrentWin(window: NvimApi.Window(window.handle), expectsReturnValue: false)
            return
          }
        }
      }

      if currentBufferIsTransient {
        self.open(url, cmd: "e")
      } else {
        self.open(url, cmd: "tabe")
      }
    }
  }

  public func openInNewTab(urls: [URL]) {
    urls.forEach { self.open($0, cmd: "tabe") }
  }

  public func openInCurrentTab(url: URL) {
    self.open(url, cmd: "e")
  }

  public func openInHorizontalSplit(urls: [URL]) {
    urls.forEach { self.open($0, cmd: "sp") }
  }

  public func openInVerticalSplit(urls: [URL]) {
    urls.forEach { self.open($0, cmd: "vsp") }
  }

  public func select(buffer: NvimView.Buffer) {
    for window in self.allTabs().map({ $0.windows }).flatMap({ $0 }) {
      if window.buffer.handle == buffer.handle {
        self.nvim.setCurrentWin(window: NvimApi.Window(window.handle), expectsReturnValue: false)
        return
      }
    }

    self.nvim.command(command: "tab sb \(buffer.handle)", expectsReturnValue: false)
  }

  /// Closes the current window.
  public func closeCurrentTab() {
    // We don't have to wait here even when neovim quits since we wait in gui.async() block in neoVimStopped().
    self.nvim.command(command: "q", expectsReturnValue: false)
  }

  public func saveCurrentTab() {
    self.nvim.command(command: "w", expectsReturnValue: false)
  }

  public func saveCurrentTab(url: URL) {
    self.nvim.command(command: "w \(url.path)", expectsReturnValue: false)
  }

  public func closeCurrentTabWithoutSaving() {
    self.nvim.command(command: "q!", expectsReturnValue: false)
  }

  public func quitNeoVimWithoutSaving() {
    self.nvim.command(command: "qa!", expectsReturnValue: false)
    self.delegate?.neoVimStopped()
    self.waitForNeoVimToQuit()
  }

  public func vimOutput(of command: String) -> String {
    return self.nvim.commandOutput(str: command).value ?? ""
  }

  public func cursorGo(to position: Position) {
    guard let curWin = self.nvim.getCurrentWin().value else {
      return
    }

    self.nvim.winSetCursor(window: curWin, pos: [position.row, position.column])
  }

  public func didBecomeMain() {
    self.uiClient.focusGained(true)
  }

  public func didResignMain() {
    self.uiClient.focusGained(false)
  }

  func waitForNeoVimToQuit() {
    self.uiClient.neoVimQuitCondition.lock()
    defer { self.uiClient.neoVimQuitCondition.unlock() }
    while self.uiClient.neoVimHasQuit == false
          && self.uiClient.neoVimQuitCondition.wait(until: Date(timeIntervalSinceNow: neoVimQuitTimeout)) {}
  }

  private func `open`(_ url: URL, cmd: String) {
    self.nvim.command(command: "\(cmd) \(url.path)", expectsReturnValue: false)
  }

  private func neoVimBuffer(for buf: NvimApi.Buffer, currentBuffer: NvimApi.Buffer?) -> NvimView.Buffer? {
    guard let info = self.nvim.getBufGetInfo(buffer: buf).value else {
      return nil
    }

    let current = buf == currentBuffer
    guard let path = info["filename"]?.stringValue,
          let dirty = info["modified"]?.boolValue,
          let buftype = info["buftype"]?.stringValue,
          let listed = info["buflisted"]?.boolValue
      else {
      return nil
    }

    guard listed else {
      return nil
    }
    let url = path == "" || buftype != "" ? nil : URL(fileURLWithPath: path)

    return NvimView.Buffer(apiBuffer: buf,
                           url: url,
                           type: buftype,
                           isDirty: dirty,
                           isCurrent: current)
  }

  private func neoVimWindow(for window: NvimApi.Window,
                            currentWindow: NvimApi.Window?,
                            currentBuffer: NvimApi.Buffer?) -> NvimView.Window? {

    guard let buf = self.nvim.winGetBuf(window: window).value else {
      return nil
    }

    guard let buffer = self.neoVimBuffer(for: buf, currentBuffer: currentBuffer) else {
      return nil
    }

    return NvimView.Window(apiWindow: window, buffer: buffer, isCurrentInTab: window == currentWindow)
  }

  private func neoVimTab(for tabpage: NvimApi.Tabpage,
                         currentTabpage: NvimApi.Tabpage?,
                         currentBuffer: NvimApi.Buffer?) -> NvimView.Tabpage? {

    let curWinInTab = self.nvim.tabpageGetWin(tabpage: tabpage).value

    let windows: [NvimView.Window] = self.nvim.tabpageListWins(tabpage: tabpage)
                                    .value?
                                    .flatMap {
      self.neoVimWindow(for: $0,
                        currentWindow: curWinInTab,
                        currentBuffer: currentBuffer)
    } ?? []

    return NvimView.Tabpage(apiTabpage: tabpage, windows: windows, isCurrent: tabpage == currentTabpage)
  }
}

fileprivate let neoVimQuitTimeout = TimeInterval(5)
