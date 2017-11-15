/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

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
    return self.agent.buffers().first { $0.isCurrent }
  }

  public func allBuffers() -> [NeoVimBuffer] {
    return self.agent.tabs().map { $0.allBuffers() }.flatMap { $0 }
  }

  public func hasDirtyDocs() -> Bool {
    return self.agent.hasDirtyDocs()
  }

  public func isCurrentBufferDirty() -> Bool {
    let curBuf = self.currentBuffer()
    return curBuf?.isDirty ?? true
  }

  public func newTab() {
    self.exec(command: "tabe")
  }

  public func `open`(urls: [URL]) {
    let tabs = self.agent.tabs()
    let buffers = self.allBuffers()
    let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

    urls.enumerated().forEach { (idx, url) in
      if buffers.filter({ $0.url == url }).first != nil {
        for window in tabs.map({ $0.windows }).flatMap({ $0 }) {
          if window.buffer.url == url {
            self.agent.select(window)
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
    for window in self.agent.tabs().map({ $0.windows }).flatMap({ $0 }) {
      if window.buffer.handle == buffer.handle {
        self.agent.select(window)
        return
      }
    }
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
    return self.agent.vimCommandOutput(command) ?? ""
  }

  public func cursorGo(to position: Position) {
    self.agent.cursorGo(toRow: Int32(position.row), column: Int32(position.column))
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
          && self.agent.neoVimQuitCondition.wait(until: Date(timeIntervalSinceNow: neoVimQuitTimeout)) { }
  }

  /**
   Does the following
   - normal mode: `:command<CR>`
   - else: `:<Esc>:command<CR>`

   We don't use NeoVimAgent.vimCommand because if we do for example "e /some/file"
   and its swap file already exists, then NeoVimServer spins and become unresponsive.
  */
  fileprivate func exec(command cmd: String) {
    switch self.mode {
    case .normal:
      self.agent.vimInput(":\(cmd)<CR>")
    default:
      self.agent.vimInput("<Esc>:\(cmd)<CR>")
    }
  }

  fileprivate func `open`(_ url: URL, cmd: String) {
    let path = url.path
    guard let escapedFileName = self.agent.escapedFileName(path) else {
      self.logger.fault("Escaped file name returned nil.")
      return
    }

    self.exec(command: "\(cmd) \(escapedFileName)")
  }
}

fileprivate let neoVimQuitTimeout = TimeInterval(5)
