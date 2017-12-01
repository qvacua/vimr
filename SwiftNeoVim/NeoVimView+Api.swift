/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack

extension NeoVimView {

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
  public func currentBuffer() -> NeoVimBuffer? {
    guard let buf = self.nvim.getCurrentBuf().value else {
      return nil
    }

    return self.neoVimBuffer(for: buf, currentBuffer: buf)
  }

  public func allBuffers() -> [NeoVimBuffer] {
    let curBuf = self.nvim.getCurrentBuf().value
    return self.nvim.listBufs()
             .value?
             .flatMap { self.neoVimBuffer(for: $0, currentBuffer: curBuf) } ?? []
  }

  public func isCurrentBufferDirty() -> Bool {
    return self.currentBuffer()?.isDirty ?? false
  }

  public func allTabs() -> [NeoVimTab] {
    let curBuf = self.nvim.getCurrentBuf().value
    let curTab = self.nvim.getCurrentTabpage().value

    return self.nvim.listTabpages()
             .value?
             .flatMap { self.neoVimTab(for: $0, currentTabpage: curTab, currentBuffer: curBuf) } ?? []
  }

  public func newTab() {
    self.exec(command: "tabe")
  }

  public func `open`(urls: [URL]) {
    let tabs = self.allTabs()
    let buffers = tabs.map { $0.windows }.flatMap { $0 }.map { $0.buffer }
    let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

    urls.enumerated().forEach { (idx, url) in
      if buffers.filter({ $0.url == url }).first != nil {
        for window in tabs.map({ $0.windows }).flatMap({ $0 }) {
          if window.buffer.url == url {
            self.nvim.setCurrentWin(window: Nvim.Window(window.handle), expectsReturnValue: false)
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

  public func select(buffer: NeoVimBuffer) {
    for window in self.allTabs().map({ $0.windows }).flatMap({ $0 }) {
      if window.buffer.handle == buffer.handle {
        self.nvim.setCurrentWin(window: Nvim.Window(window.handle), expectsReturnValue: false)
        return
      }
    }

    self.nvim.command(command: "tab sb \(buffer.handle)")
  }

  /// Closes the current window.
  public func closeCurrentTab() {
    // We don't have to wait here even when neovim quits since we wait in gui.async() block in neoVimStopped().
    self.exec(command: "q")
  }

  public func saveCurrentTab() {
    self.exec(command: "w")
  }

  public func saveCurrentTab(url: URL) {
    let path = url.path
    guard let escapedFileName = self.agent.escapedFileName(path) else {
      self.logger.fault("Escaped file name returned nil.")
      return
    }

    self.exec(command: "w \(escapedFileName)")
  }

  public func closeCurrentTabWithoutSaving() {
    self.exec(command: "q!")
  }

  public func quitNeoVimWithoutSaving() {
    self.exec(command: "qa!")
    self.delegate?.neoVimStopped()
    self.waitForNeoVimToQuit()
  }

  public func vimOutput(of command: String) -> String {
    return self.nvim.commandOutput(str: command) ?? ""
  }

  public func cursorGo(to position: Position) {
    guard let curWin = self.nvim.getCurrentWin().value else {
      return
    }

    self.nvim.winSetCursor(window: curWin, pos: [position.row, position.column])
  }

  public func didBecomeMain() {
    self.agent.focusGained(true)
  }

  public func didResignMain() {
    self.agent.focusGained(false)
  }

  func waitForNeoVimToQuit() {
    self.agent.neoVimQuitCondition.lock()
    defer { self.agent.neoVimQuitCondition.unlock() }
    while self.agent.neoVimHasQuit == false
          && self.agent.neoVimQuitCondition.wait(until: Date(timeIntervalSinceNow: neoVimQuitTimeout)) {}
  }

  /**
   Does the following
   - normal mode: `:command<CR>`
   - else: `:<Esc>:command<CR>`

   We don't use NeoVimAgent.vimCommand because if we do for example "e /some/file"
   and its swap file already exists, then NeoVimServer spins and become unresponsive.
  */
  private func exec(command cmd: String) {
    switch self.mode {
    case .normal:
      self.agent.vimInput(":\(cmd)<CR>")
    default:
      self.agent.vimInput("<Esc>:\(cmd)<CR>")
    }
  }

  private func `open`(_ url: URL, cmd: String) {
    let path = url.path
    guard let escapedFileName = self.agent.escapedFileName(path) else {
      self.logger.fault("Escaped file name returned nil.")
      return
    }

    self.exec(command: "\(cmd) \(escapedFileName)")
  }

  private func neoVimBuffer(for buf: Nvim.Buffer, currentBuffer: Nvim.Buffer?) -> NeoVimBuffer? {
    guard let path = self.nvim.bufGetName(buffer: buf).value else {
      return nil
    }

    guard let dirty = self.nvim.bufGetOption(buffer: buf, name: "mod").value?.boolValue else {
      return nil
    }

    guard let buftype = self.nvim.bufGetOption(buffer: buf, name: "buftype").value else {
      return nil
    }

    let readonly = buftype != ""
    let current = buf == currentBuffer

    return NeoVimBuffer(handle: buf.handle, unescapedPath: path, dirty: dirty, readOnly: readonly, current: current)
  }

  private func neoVimWindow(for window: Nvim.Window,
                            currentWindow: Nvim.Window?,
                            currentBuffer: Nvim.Buffer?) -> NeoVimWindow? {

    guard let buf = self.nvim.winGetBuf(window: window).value else {
      return nil
    }

    guard let buffer = self.neoVimBuffer(for: buf, currentBuffer: currentBuffer) else {
      return nil
    }

    return NeoVimWindow(handle: window.handle, buffer: buffer, currentInTab: window == currentWindow)
  }

  private func neoVimTab(for tabpage: Nvim.Tabpage,
                         currentTabpage: Nvim.Tabpage?,
                         currentBuffer: Nvim.Buffer?) -> NeoVimTab? {

    let curWinInTab = self.nvim.tabpageGetWin(tabpage: tabpage).value

    let windows: [NeoVimWindow] = self.nvim.tabpageListWins(tabpage: tabpage)
                                    .value?
                                    .flatMap {
      self.neoVimWindow(for: $0,
                        currentWindow: curWinInTab,
                        currentBuffer: currentBuffer)
    } ?? []

    return NeoVimTab(handle: tabpage.handle, windows: windows, current: tabpage == currentTabpage)
  }
}

fileprivate let neoVimQuitTimeout = TimeInterval(5)
