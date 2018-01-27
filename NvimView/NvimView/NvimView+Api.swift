/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack
import RxSwift

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

  public func currentBufferSync() -> NvimView.Buffer? {
    guard let buf = self.nvim.getCurrentBuf().value else {
      return nil
    }

    return self.neoVimBuffer(for: buf, currentBuffer: buf)
  }

  public func currentBuffer() -> Single<NvimView.Buffer> {
    return Single<NvimView.Buffer>.create { single in
        let disposable = Disposables.create()

        guard let buf = self.nvim.getCurrentBuf().value else {
          single(.error(NvimView.Error.api("Could not get the current buffer.")))
          return disposable
        }

        guard let buffer = self.neoVimBuffer(for: buf, currentBuffer: buf) else {
          single(.error(NvimView.Error.api("Could not get the info for buffer \(buf).")))
          return disposable
        }

        single(.success(buffer))
        return disposable
      }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func allBuffers() -> Single<[NvimView.Buffer]> {
    return Single<[NvimView.Buffer]>.create { single in
        let disposable = Disposables.create()

        guard let curBuf = self.nvim.getCurrentBuf().value else {
          single(.error(NvimView.Error.api("Could not get the current buffer.")))
          return disposable
        }

        guard let bufs = self.nvim.listBufs().value else {
          single(.error(NvimView.Error.api("Could not get the list of buffers.")))
          return disposable
        }

        let buffers = bufs.flatMap { self.neoVimBuffer(for: $0, currentBuffer: curBuf) }
        single(.success(buffers))

        return disposable
      }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func isCurrentBufferDirty() -> Single<Bool> {
    return self
      .currentBuffer()
      .map { $0.isDirty }
  }

  public func isCurrentBufferDirtySync() -> Bool {
    guard let buf = self.nvim.getCurrentBuf().value else {
      return false
    }

    guard let modified = self.nvim.bufGetOption(buffer: buf, name: "modified").value?.boolValue else {
      return false
    }

    return modified
  }

  public func allTabs() -> Single<[NvimView.Tabpage]> {
    return Single<[NvimView.Tabpage]>.create { single in
        let disposable = Disposables.create()

        guard let curBuf = self.nvim.getCurrentBuf().value else {
          single(.error(NvimView.Error.api("Could not get the current buffer.")))
          return disposable
        }

        guard let curTab = self.nvim.getCurrentTabpage().value else {
          single(.error(NvimView.Error.api("Could not get the current tabpage.")))
          return disposable
        }

        guard let tabs = self.nvim.listTabpages().value else {
          single(.error(NvimView.Error.api("Could not get the list of tabpages.")))
          return disposable
        }

        let tabpages = tabs.flatMap { self.neoVimTab(for: $0, currentTabpage: curTab, currentBuffer: curBuf) }
        single(.success(tabpages))

        return disposable
      }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func newTab() {
    self.nvim.command(command: "tabe", expectsReturnValue: false)
  }

  public func `open`(urls: [URL]) {
    self
      .allTabs()
      .subscribe(onSuccess: { tabs in
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
      })
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
    self
      .allTabs()
      .map { tabs in
        return tabs.map { $0.windows }.flatMap { $0 }
      }
      .subscribe(onSuccess: { wins in
        if let win = wins.first(where: { $0.buffer == buffer }) {
          self.nvim.setCurrentWin(window: NvimApi.Window(win.handle), expectsReturnValue: false)
          return
        }

        self.nvim.command(command: "tab sb \(buffer.handle)", expectsReturnValue: false)
      })
  }

  /// Closes the current window.
  public func closeCurrentTab() {
    self.nvim.command(command: "q", expectsReturnValue: true)
  }

  public func saveCurrentTab() {
    self.nvim.command(command: "w", expectsReturnValue: true)
  }

  public func saveCurrentTab(url: URL) {
    self.nvim.command(command: "w \(url.path)", expectsReturnValue: true)
  }

  public func closeCurrentTabWithoutSaving() {
    self.nvim.command(command: "q!", expectsReturnValue: true)
  }

  public func quitNeoVimWithoutSaving() {
    self.bridgeLogger.mark()
    self.nvim.command(command: "qa!", expectsReturnValue: true)
  }

  public func vimOutput(of command: String) -> String {
    return self.nvim.commandOutput(command: command).value ?? ""
  }

  public func cursorGo(to position: Position) {
    guard let curWin = self.nvim.getCurrentWin().value else {
      return
    }

    self.nvim.winSetCursor(window: curWin, pos: [position.row, position.column])
  }

  public func didBecomeMain() {
    self.uiBridge.focusGained(true)
  }

  public func didResignMain() {
    self.uiBridge.focusGained(false)
  }

  func waitForNeoVimToQuit() {
    self.uiBridge.nvimQuitCondition.lock()
    defer { self.uiBridge.nvimQuitCondition.unlock() }
    while self.uiBridge.isNvimQuit == false
          && self.uiBridge.nvimQuitCondition.wait(until: Date(timeIntervalSinceNow: neoVimQuitTimeout)) {}
  }

  private func `open`(_ url: URL, cmd: String) {
    self.nvim.command(command: "\(cmd) \(url.path)", expectsReturnValue: false)
  }

  func neoVimBuffer(for buf: NvimApi.Buffer, currentBuffer: NvimApi.Buffer?) -> NvimView.Buffer? {
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

    let url = path == "" || buftype != "" ? nil : URL(fileURLWithPath: path)

    return NvimView.Buffer(apiBuffer: buf,
                           url: url,
                           type: buftype,
                           isDirty: dirty,
                           isCurrent: current,
                           isListed: listed)
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

private let neoVimQuitTimeout = TimeInterval(5)
