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
    guard let buf = self.nvim.getCurrentBuf().subscribeOn(self.nvimApiScheduler).syncValue() else {
      return nil
    }

    return self
      .neoVimBuffer(for: buf, currentBuffer: buf)
      .subscribeOn(self.nvimApiScheduler)
      .syncValue()
  }

  public func currentBuffer() -> Single<NvimView.Buffer> {
    return self.nvim
      .getCurrentBuf()
      .flatMap { self.neoVimBuffer(for: $0, currentBuffer: $0) }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func allBuffers() -> Single<[NvimView.Buffer]> {
    return self.nvim
      .getCurrentBuf()
      .flatMap { curBuf in
        self.nvim
          .listBufs()
          .asObservable()
          .flatMap { bufs -> Observable<[NvimView.Buffer]> in
            Observable.combineLatest(
              bufs.map { self.neoVimBuffer(for: $0, currentBuffer: curBuf).asObservable() }
            )
          }
          .asSingle()
      }
      .subscribeOn(self.nvimApiScheduler)
  }

  public func isCurrentBufferDirty() -> Single<Bool> {
    return self
      .currentBuffer()
      .map { $0.isDirty }
  }

  public func isCurrentBufferDirtySync() -> Bool {
    guard let buf = self.nvim.getCurrentBuf().subscribeOn(self.nvimApiScheduler).syncValue() else {
      return false
    }

    let mod = self.nvim.bufGetOption(buffer: buf, name: "modified").subscribeOn(self.nvimApiScheduler).syncValue()
    guard let modified = mod?.boolValue else {
      return false
    }

    return modified
  }

  public func allTabs() -> Single<[NvimView.Tabpage]> {
    return Observable.zip(
        self.nvim.getCurrentBuf().asObservable(),
        self.nvim.getCurrentTabpage().asObservable()
      ) { (curBuf: $0, curTab: $1) }
      .flatMap { tuple in
        self.nvim
          .listTabpages()
          .asObservable()
          .flatMap { tabs -> Observable<[NvimView.Tabpage]> in
            Observable.combineLatest(
              tabs.map { tab in
                self.neoVimTab(for: tab, currentTabpage: tuple.curTab, currentBuffer: tuple.curBuf).asObservable()
              }
            )
          }
      }
      .subscribeOn(self.nvimApiScheduler)
      .asSingle()
  }

  public func newTab() -> Single<Void> {
    return self.nvim
      .command(command: "tabe", expectsReturnValue: false)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func `open`(urls: [URL]) -> Single<Void> {
    return self
      .allTabs()
      .asObservable()
      .flatMap { tabs -> Observable<[Void]> in
        let buffers = tabs.map { $0.windows }.flatMap { $0 }.map { $0.buffer }
        let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

        return Observable.combineLatest(
          urls.map { url -> Observable<Void> in
            let bufExists = buffers.contains { $0.url == url }
            let wins = tabs.map({ $0.windows }).flatMap({ $0 })
            if let win = bufExists ? wins.first(where: { win in win.buffer.url == url }) : nil {
              return self.nvim
                .setCurrentWin(window: NvimApi.Window(win.handle), expectsReturnValue: false)
                .asObservable()
            }

            return currentBufferIsTransient ? self.open(url, cmd: "e").asObservable()
              : self.open(url, cmd: "tabe").asObservable()
          }
        )
      }
      .map { _ in () }
      .subscribeOn(self.nvimApiScheduler)
      .asSingle()
  }

  public func openInNewTab(urls: [URL]) -> Single<Void> {
    return Observable.combineLatest(urls.map { url in self.open(url, cmd: "tabe").asObservable() })
      .map { _ in () }
      .subscribeOn(self.nvimApiScheduler)
      .asSingle()
  }

  public func openInCurrentTab(url: URL) -> Single<Void> {
    return self.open(url, cmd: "e")
  }

  public func openInHorizontalSplit(urls: [URL]) -> Single<Void> {
    return Observable.combineLatest(urls.map { url in self.open(url, cmd: "sp").asObservable() })
      .map { _ in () }
      .subscribeOn(self.nvimApiScheduler)
      .asSingle()
  }

  public func openInVerticalSplit(urls: [URL]) -> Single<Void> {
    return Observable.combineLatest(urls.map { url in self.open(url, cmd: "vsp").asObservable() })
      .map { _ in () }
      .subscribeOn(self.nvimApiScheduler)
      .asSingle()
  }

  public func select(buffer: NvimView.Buffer) -> Single<Void> {
    return self
      .allTabs()
      .map { tabs in
        return tabs.map { $0.windows }.flatMap { $0 }
      }
      .flatMap { wins -> Single<Void> in
        if let win = wins.first(where: { $0.buffer == buffer }) {
          return self.nvim.setCurrentWin(window: NvimApi.Window(win.handle), expectsReturnValue: false)
        }

        return self.nvim.command(command: "tab sb \(buffer.handle)", expectsReturnValue: false)
      }
      .subscribeOn(self.nvimApiScheduler)
  }

/// Closes the current window.
  public func closeCurrentTab() -> Single<Void> {
    return self.nvim
      .command(command: "q", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func saveCurrentTab() -> Single<Void> {
    return self.nvim
      .command(command: "w", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func saveCurrentTab(url: URL) -> Single<Void> {
    return self.nvim
      .command(command: "w \(url.path)", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func closeCurrentTabWithoutSaving() -> Single<Void> {
    return self.nvim
      .command(command: "q!", expectsReturnValue: true)
      .subscribeOn(self.nvimApiScheduler)
  }

  public func quitNeoVimWithoutSaving() -> Single<Void> {
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

  public func cursorGo(to position: Position) -> Single<Void> {
    return self.nvim
      .getCurrentWin()
      .flatMap { curWin in
        self.nvim.winSetCursor(window: curWin, pos: [position.row, position.column])
      }
      .subscribeOn(self.nvimApiScheduler)
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

  private func `open`(_ url: URL, cmd: String) -> Single<Void> {
    return self.nvim
      .command(command: "\(cmd) \(url.path)", expectsReturnValue: false)
      .subscribeOn(self.nvimApiScheduler)
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
  }

  private func neoVimWindow(for window: NvimApi.Window,
                            currentWindow: NvimApi.Window?,
                            currentBuffer: NvimApi.Buffer?) -> Single<NvimView.Window> {

    return self.nvim
      .winGetBuf(window: window)
      .flatMap { buf in
        self.neoVimBuffer(for: buf, currentBuffer: currentBuffer)
      }
      .map { buffer in NvimView.Window(apiWindow: window, buffer: buffer, isCurrentInTab: window == currentWindow) }
  }

  private func neoVimTab(for tabpage: NvimApi.Tabpage,
                         currentTabpage: NvimApi.Tabpage?,
                         currentBuffer: NvimApi.Buffer?) -> Single<NvimView.Tabpage> {

    return self.nvim
      .tabpageGetWin(tabpage: tabpage)
      .flatMap { curWinInTab in
        self.nvim
          .tabpageListWins(tabpage: tabpage)
          .asObservable()
          .flatMap { wins -> Observable<[NvimView.Window]> in
            Observable.combineLatest(
              wins.map { self.neoVimWindow(for: $0, currentWindow: curWinInTab, currentBuffer: currentBuffer).asObservable() }
            )
          }
          .asSingle()
      }
      .map { wins in NvimView.Tabpage(apiTabpage: tabpage, windows: wins, isCurrent: tabpage == currentTabpage) }
  }
}

private let neoVimQuitTimeout = TimeInterval(5)
