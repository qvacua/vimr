/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack
import RxSwift
import MessagePack

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

  public func currentBuffer() -> Single<NvimView.Buffer> {
    return self.nvim
      .getCurrentBuf()
      .flatMap { self.neoVimBuffer(for: $0, currentBuffer: $0) }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func allBuffers() -> Single<[NvimView.Buffer]> {
    return Single
      .zip(self.nvim.getCurrentBuf(), self.nvim.listBufs()) { (curBuf: $0, bufs: $1) }
      .map { tuple in tuple.bufs.map { buf in self.neoVimBuffer(for: buf, currentBuffer: tuple.curBuf) } }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func isCurrentBufferDirty() -> Single<Bool> {
    return self
      .currentBuffer()
      .map { $0.isDirty }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func allTabs() -> Single<[NvimView.Tabpage]> {
    return Single.zip(self.nvim.getCurrentBuf(),
                      self.nvim.getCurrentTabpage(),
                      self.nvim.listTabpages()) { (curBuf: $0, curTab: $1, tabs: $2) }
      .map { tuple in
        return tuple.tabs.map { tab in
          return self.neoVimTab(for: tab, currentTabpage: tuple.curTab, currentBuffer: tuple.curBuf)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func newTab() -> Completable {
    return self.nvim
      .command(command: "tabe", expectsReturnValue: false)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func `open`(urls: [URL]) -> Completable {
    return self
      .allTabs()
      .flatMapCompletable { tabs -> Completable in
        let buffers = tabs.map { $0.windows }.flatMap { $0 }.map { $0.buffer }
        let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

        return Completable.concat(
          urls.map { url -> Completable in
            let bufExists = buffers.contains { $0.url == url }
            let wins = tabs.map({ $0.windows }).flatMap({ $0 })
            if let win = bufExists ? wins.first(where: { win in win.buffer.url == url }) : nil {
              return self.nvim.setCurrentWin(window: NvimApi.Window(win.handle), expectsReturnValue: false)
            }

            return currentBufferIsTransient ? self.open(url, cmd: "e") : self.open(url, cmd: "tabe")
          }
        )
      }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func openInNewTab(urls: [URL]) -> Completable {
    return Completable
      .concat(urls.map { url in self.open(url, cmd: "tabe") })
      .subscribeOn(self.nvimApiScheduler)
  }

  public func openInCurrentTab(url: URL) -> Completable {
    return self.open(url, cmd: "e")
  }

  public func openInHorizontalSplit(urls: [URL]) -> Completable {
    return Completable
      .concat(urls.map { url in self.open(url, cmd: "sp") })
      .subscribeOn(self.nvimApiScheduler)
  }

  public func openInVerticalSplit(urls: [URL]) -> Completable {
    return Completable
      .concat(urls.map { url in self.open(url, cmd: "vsp") })
      .subscribeOn(self.nvimApiScheduler)
  }

  public func select(buffer: NvimView.Buffer) -> Completable {
    return self
      .allTabs()
      .map { tabs in tabs.map { $0.windows }.flatMap { $0 } }
      .flatMapCompletable { wins -> Completable in
        if let win = wins.first(where: { $0.buffer == buffer }) {
          return self.nvim.setCurrentWin(window: NvimApi.Window(win.handle), expectsReturnValue: false)
        }

        return self.nvim.command(command: "tab sb \(buffer.handle)", expectsReturnValue: false)
      }
      .subscribeOn(self.nvimApiScheduler)
  }

/// Closes the current window.
  public func closeCurrentTab() -> Completable {
    return self.nvim
      .command(command: "q", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func saveCurrentTab() -> Completable {
    return self.nvim
      .command(command: "w", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func saveCurrentTab(url: URL) -> Completable {
    return self.nvim
      .command(command: "w \(url.path)", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func closeCurrentTabWithoutSaving() -> Completable {
    return self.nvim
      .command(command: "q!", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func quitNeoVimWithoutSaving() -> Completable {
    self.bridgeLogger.mark()
    return self.nvim
      .command(command: "qa!", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func vimOutput(of command: String) -> Single<String> {
    return self.nvim
      .commandOutput(str: command)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func cursorGo(to position: Position) -> Completable {
    return self.nvim
      .getCurrentWin()
      .flatMapCompletable { curWin in self.nvim.winSetCursor(window: curWin, pos: [position.row, position.column]) }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func didBecomeMain() -> Completable {
    return self.uiBridge.focusGained(true)
  }

  public func didResignMain() -> Completable {
    return self.uiBridge.focusGained(false)
  }

  func neoVimBuffer(for buf: NvimApi.Buffer, currentBuffer: NvimApi.Buffer?) -> Single<NvimView.Buffer> {
    return self.nvim
      .getBufGetInfo(buffer: buf)
      .map { info -> NvimView.Buffer in
        let current = buf == currentBuffer
        guard let path = info["filename"]?.stringValue,
              let dirty = info["modified"]?.boolValue,
              let buftype = info["buftype"]?.stringValue,
              let listed = info["buflisted"]?.boolValue
          else {
          throw NvimApi.Error.exception(message: "Could not convert values from the dictionary.")
        }

        let url = path == "" || buftype != "" ? nil : URL(fileURLWithPath: path)

        return NvimView.Buffer(apiBuffer: buf,
                               url: url,
                               type: buftype,
                               isDirty: dirty,
                               isCurrent: current,
                               isListed: listed)
      }
      .subscribeOn(self.nvimApiScheduler)
  }

  func waitForNeoVimToQuit() {
    self.uiBridge.nvimQuitCondition.lock()
    defer { self.uiBridge.nvimQuitCondition.unlock() }
    while self.uiBridge.isNvimQuit == false
          && self.uiBridge.nvimQuitCondition.wait(until: Date(timeIntervalSinceNow: neoVimQuitTimeout)) {}
  }

  private func `open`(_ url: URL, cmd: String) -> Completable {
    return self.nvim
      .command(command: "\(cmd) \(url.path)", expectsReturnValue: false)
      .subscribeOn(self.nvimApiScheduler)
  }

  private func neoVimWindow(for window: NvimApi.Window,
                            currentWindow: NvimApi.Window?,
                            currentBuffer: NvimApi.Buffer?) -> Single<NvimView.Window> {

    return self.nvim
      .winGetBuf(window: window)
      .flatMap { buf in self.neoVimBuffer(for: buf, currentBuffer: currentBuffer) }
      .map { buffer in NvimView.Window(apiWindow: window, buffer: buffer, isCurrentInTab: window == currentWindow) }
  }

  private func neoVimTab(for tabpage: NvimApi.Tabpage,
                         currentTabpage: NvimApi.Tabpage?,
                         currentBuffer: NvimApi.Buffer?) -> Single<NvimView.Tabpage> {

    return Single.zip(
        self.nvim.tabpageGetWin(tabpage: tabpage),
        self.nvim.tabpageListWins(tabpage: tabpage)) { (curWin: $0, wins: $1) }
      .map { tuple in
        tuple.wins.map { win in
          return self.neoVimWindow(for: win, currentWindow: tuple.curWin, currentBuffer: currentBuffer)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .map { wins in NvimView.Tabpage(apiTabpage: tabpage, windows: wins, isCurrent: tabpage == currentTabpage) }
  }
}

private let neoVimQuitTimeout = TimeInterval(5)
