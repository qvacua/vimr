/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import MessagePack

extension NvimView {

  public func isBlocked() -> Single<Bool> {
    return self.api.getMode().map { dict in dict["blocking"]?.boolValue ?? false }
  }

  public func hasDirtyBuffers() -> Single<Bool> {
    return self.api.getDirtyStatus()
  }

  public func waitTillNvimExits() {
    self.nvimExitedCondition.wait(for: 5)
  }

  public func enterResizeMode() {
    self.currentlyResizing = true
    self.markForRenderWholeView()
  }

  public func exitResizeMode() {
    self.currentlyResizing = false
    self.markForRenderWholeView()
    self.resizeNeoVimUi(to: self.bounds.size)
  }

  public func currentBuffer() -> Single<NvimView.Buffer> {
    return self.api
      .getCurrentBuf()
      .flatMap { self.neoVimBuffer(for: $0, currentBuffer: $0) }
      .subscribeOn(self.scheduler)
  }

  public func allBuffers() -> Single<[NvimView.Buffer]> {
    return Single
      .zip(self.api.getCurrentBuf(), self.api.listBufs()) { (curBuf: $0, bufs: $1) }
      .map { tuple in tuple.bufs.map { buf in self.neoVimBuffer(for: buf, currentBuffer: tuple.curBuf) } }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribeOn(self.scheduler)
  }

  public func isCurrentBufferDirty() -> Single<Bool> {
    return self
      .currentBuffer()
      .map { $0.isDirty }
      .subscribeOn(self.scheduler)
  }

  public func allTabs() -> Single<[NvimView.Tabpage]> {
    return Single.zip(self.api.getCurrentBuf(),
                      self.api.getCurrentTabpage(),
                      self.api.listTabpages()) { (curBuf: $0, curTab: $1, tabs: $2) }
      .map { tuple in
        return tuple.tabs.map { tab in
          return self.neoVimTab(for: tab, currentTabpage: tuple.curTab, currentBuffer: tuple.curBuf)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribeOn(self.scheduler)
  }

  public func newTab() -> Completable {
    return self.api
      .command(command: "tabe")
      .subscribeOn(self.scheduler)
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
              return self.api.setCurrentWin(window: RxNeovimApi.Window(win.handle))
            }

            return currentBufferIsTransient ? self.open(url, cmd: "e") : self.open(url, cmd: "tabe")
          }
        )
      }
      .subscribeOn(self.scheduler)
  }

  public func openInNewTab(urls: [URL]) -> Completable {
    return Completable
      .concat(urls.map { url in self.open(url, cmd: "tabe") })
      .subscribeOn(self.scheduler)
  }

  public func openInCurrentTab(url: URL) -> Completable {
    return self.open(url, cmd: "e")
  }

  public func openInHorizontalSplit(urls: [URL]) -> Completable {
    return Completable
      .concat(urls.map { url in self.open(url, cmd: "sp") })
      .subscribeOn(self.scheduler)
  }

  public func openInVerticalSplit(urls: [URL]) -> Completable {
    return Completable
      .concat(urls.map { url in self.open(url, cmd: "vsp") })
      .subscribeOn(self.scheduler)
  }

  public func select(buffer: NvimView.Buffer) -> Completable {
    return self
      .allTabs()
      .map { tabs in tabs.map { $0.windows }.flatMap { $0 } }
      .flatMapCompletable { wins -> Completable in
        if let win = wins.first(where: { $0.buffer == buffer }) {
          return self.api.setCurrentWin(window: RxNeovimApi.Window(win.handle))
        }

        return self.api.command(command: "tab sb \(buffer.handle)")
      }
      .subscribeOn(self.scheduler)
  }

  public func goTo(line: Int) -> Completable {
    return self.api.command(command: "\(line)")
  }

/// Closes the current window.
  public func closeCurrentTab() -> Completable {
    return self.api
      .command(command: "q")
      .subscribeOn(self.scheduler)
  }

  public func saveCurrentTab() -> Completable {
    return self.api
      .command(command: "w")
      .subscribeOn(self.scheduler)
  }

  public func saveCurrentTab(url: URL) -> Completable {
    return self.api
      .command(command: "w \(url.path)")
      .subscribeOn(self.scheduler)
  }

  public func closeCurrentTabWithoutSaving() -> Completable {
    return self.api
      .command(command: "q!")
      .subscribeOn(self.scheduler)
  }

  public func quitNeoVimWithoutSaving() -> Completable {
    return self.api
      .command(command: "qa!")
      .subscribeOn(self.scheduler)
  }

  public func vimOutput(of command: String) -> Single<String> {
    return self.api
      .exec(src: command, output: true)
      .subscribeOn(self.scheduler)
  }

  public func cursorGo(to position: Position) -> Completable {
    return self.api
      .getCurrentWin()
      .flatMapCompletable { curWin in self.api.winSetCursor(window: curWin, pos: [position.row, position.column]) }
      .subscribeOn(self.scheduler)
  }

  public func didBecomeMain() -> Completable {
    return self.bridge.focusGained(true)
  }

  public func didResignMain() -> Completable {
    return self.bridge.focusGained(false)
  }

  func neoVimBuffer(for buf: RxNeovimApi.Buffer, currentBuffer: RxNeovimApi.Buffer?) -> Single<NvimView.Buffer> {
    return self.api
      .bufGetInfo(buffer: buf)
      .map { info -> NvimView.Buffer in
        let current = buf == currentBuffer
        guard let path = info["filename"]?.stringValue,
              let dirty = info["modified"]?.boolValue,
              let buftype = info["buftype"]?.stringValue,
              let listed = info["buflisted"]?.boolValue
          else {
          throw RxNeovimApi.Error.exception(message: "Could not convert values from the dictionary.")
        }

        let url = path == "" || buftype != "" ? nil : URL(fileURLWithPath: path)

        return NvimView.Buffer(apiBuffer: buf,
                               url: url,
                               type: buftype,
                               isDirty: dirty,
                               isCurrent: current,
                               isListed: listed)
      }
      .subscribeOn(self.scheduler)
  }

  private func `open`(_ url: URL, cmd: String) -> Completable {
    return self.api
      .command(command: "\(cmd) \(url.path)")
      .subscribeOn(self.scheduler)
  }

  private func neoVimWindow(for window: RxNeovimApi.Window,
                            currentWindow: RxNeovimApi.Window?,
                            currentBuffer: RxNeovimApi.Buffer?) -> Single<NvimView.Window> {

    return self.api
      .winGetBuf(window: window)
      .flatMap { buf in self.neoVimBuffer(for: buf, currentBuffer: currentBuffer) }
      .map { buffer in NvimView.Window(apiWindow: window, buffer: buffer, isCurrentInTab: window == currentWindow) }
  }

  private func neoVimTab(for tabpage: RxNeovimApi.Tabpage,
                         currentTabpage: RxNeovimApi.Tabpage?,
                         currentBuffer: RxNeovimApi.Buffer?) -> Single<NvimView.Tabpage> {

    return Single.zip(
        self.api.tabpageGetWin(tabpage: tabpage),
        self.api.tabpageListWins(tabpage: tabpage)) { (curWin: $0, wins: $1) }
      .map { tuple in
        tuple.wins.map { win in
          return self.neoVimWindow(for: win, currentWindow: tuple.curWin, currentBuffer: currentBuffer)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .map { wins in NvimView.Tabpage(apiTabpage: tabpage, windows: wins, isCurrent: tabpage == currentTabpage) }
  }
}
