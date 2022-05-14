/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import PureLayout
import RxPack
import RxSwift
import SpriteKit

public extension NvimView {
  func toggleFramerateView() {
    // Framerate measurement; from https://stackoverflow.com/a/34039775
    if self.framerateView == nil {
      let sk = SKView(forAutoLayout: ())
      sk.showsFPS = true

      self.framerateView = sk
      self.addSubview(sk)

      sk.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
      sk.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
      sk.autoSetDimensions(to: CGSize(width: 60, height: 15))

      return
    }

    self.framerateView?.removeAllConstraints()
    self.framerateView?.removeFromSuperview()
    self.framerateView = nil
  }

  func isBlocked() -> Single<Bool> {
    self.api.getMode().map { dict in dict["blocking"]?.boolValue ?? false }
  }

  func hasDirtyBuffers() -> Single<Bool> {
    self.api.getDirtyStatus()
  }

  func waitTillNvimExits() {
    self.nvimExitedCondition.wait(for: 5)
  }

  func enterResizeMode() {
    self.currentlyResizing = true
    self.markForRenderWholeView()
  }

  func exitResizeMode() {
    self.currentlyResizing = false
    self.markForRenderWholeView()
    self.resizeNeoVimUi(to: self.bounds.size)
  }

  func currentBuffer() -> Single<NvimView.Buffer> {
    self.api
      .getCurrentBuf()
      .flatMap { self.neoVimBuffer(for: $0, currentBuffer: $0) }
      .subscribe(on: self.scheduler)
  }

  func allBuffers() -> Single<[NvimView.Buffer]> {
    Single
      .zip(self.api.getCurrentBuf(), self.api.listBufs()) { (curBuf: $0, bufs: $1) }
      .map { tuple in tuple.bufs.map { buf in
        self.neoVimBuffer(for: buf, currentBuffer: tuple.curBuf)
      } }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribe(on: self.scheduler)
  }

  func isCurrentBufferDirty() -> Single<Bool> {
    self
      .currentBuffer()
      .map(\.isDirty)
      .subscribe(on: self.scheduler)
  }

  func allTabs() -> Single<[NvimView.Tabpage]> {
    Single.zip(
      self.api.getCurrentBuf(),
      self.api.getCurrentTabpage(),
      self.api.listTabpages()
    ) { (curBuf: $0, curTab: $1, tabs: $2) }
      .map { tuple in
        tuple.tabs.map { tab in
          self.neoVimTab(for: tab, currentTabpage: tuple.curTab, currentBuffer: tuple.curBuf)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribe(on: self.scheduler)
  }

  func newTab() -> Completable {
    self.api
      .command(command: "tabe")
      .subscribe(on: self.scheduler)
  }

  func open(urls: [URL]) -> Completable {
    self
      .allTabs()
      .flatMapCompletable { tabs -> Completable in
        let buffers = tabs.map(\.windows).flatMap { $0 }.map(\.buffer)
        let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

        return Completable.concat(
          urls.map { url -> Completable in
            let bufExists = buffers.contains { $0.url == url }
            let wins = tabs.map(\.windows).flatMap { $0 }
            if let win = bufExists ? wins.first(where: { win in win.buffer.url == url }) : nil {
              return self.api.setCurrentWin(window: RxNeovimApi.Window(win.handle))
            }

            return currentBufferIsTransient ? self.open(url, cmd: "e") : self.open(url, cmd: "tabe")
          }
        )
      }
      .subscribe(on: self.scheduler)
  }

  func openInNewTab(urls: [URL]) -> Completable {
    Completable
      .concat(urls.map { url in self.open(url, cmd: "tabe") })
      .subscribe(on: self.scheduler)
  }

  func openInCurrentTab(url: URL) -> Completable {
    self.open(url, cmd: "e")
  }

  func openInHorizontalSplit(urls: [URL]) -> Completable {
    Completable
      .concat(urls.map { url in self.open(url, cmd: "sp") })
      .subscribe(on: self.scheduler)
  }

  func openInVerticalSplit(urls: [URL]) -> Completable {
    Completable
      .concat(urls.map { url in self.open(url, cmd: "vsp") })
      .subscribe(on: self.scheduler)
  }

  func select(buffer: NvimView.Buffer) -> Completable {
    self
      .allTabs()
      .map { tabs in tabs.map(\.windows).flatMap { $0 } }
      .flatMapCompletable { wins -> Completable in
        if let win = wins.first(where: { $0.buffer == buffer }) {
          return self.api.setCurrentWin(window: RxNeovimApi.Window(win.handle))
        }

        return self.api.command(command: "tab sb \(buffer.handle)")
      }
      .subscribe(on: self.scheduler)
  }

  func goTo(line: Int) -> Completable {
    self.api.command(command: "\(line)")
  }

  /// Closes the current window.
  func closeCurrentTab() -> Completable {
    self.api
      .command(command: "q")
      .subscribe(on: self.scheduler)
  }

  func saveCurrentTab() -> Completable {
    self.api
      .command(command: "w")
      .subscribe(on: self.scheduler)
  }

  func saveCurrentTab(url: URL) -> Completable {
    self.api
      .command(command: "w \(url.shellEscapedPath)")
      .subscribe(on: self.scheduler)
  }

  func closeCurrentTabWithoutSaving() -> Completable {
    self.api
      .command(command: "q!")
      .subscribe(on: self.scheduler)
  }

  func quitNeoVimWithoutSaving() -> Completable {
    self.api
      .command(command: "qa!")
      .subscribe(on: self.scheduler)
  }

  func vimOutput(of command: String) -> Single<String> {
    self.api
      .exec(src: command, output: true)
      .subscribe(on: self.scheduler)
  }

  func cursorGo(to position: Position) -> Completable {
    self.api
      .getCurrentWin()
      .flatMapCompletable { curWin in
        self.api.winSetCursor(window: curWin, pos: [position.row, position.column])
      }
      .subscribe(on: self.scheduler)
  }

  func didBecomeMain() -> Completable { self.bridge.focusGained(true) }

  func didResignMain() -> Completable { self.bridge.focusGained(false) }

  internal func neoVimBuffer(
    for buf: RxNeovimApi.Buffer,
    currentBuffer: RxNeovimApi.Buffer?
  ) -> Single<NvimView.Buffer> {
    self.api
      .bufGetInfo(buffer: buf)
      .map { info -> NvimView.Buffer in
        let current = buf == currentBuffer
        guard let path = info["filename"]?.stringValue,
              let dirty = info["modified"]?.boolValue,
              let buftype = info["buftype"]?.stringValue,
              let listed = info["buflisted"]?.boolValue
        else {
          throw RxNeovimApi.Error
            .exception(message: "Could not convert values from the dictionary.")
        }

        let url = path == "" || buftype != "" ? nil : URL(fileURLWithPath: path)

        return NvimView.Buffer(
          apiBuffer: buf,
          url: url,
          type: buftype,
          isDirty: dirty,
          isCurrent: current,
          isListed: listed
        )
      }
      .subscribe(on: self.scheduler)
  }

  private func open(_ url: URL, cmd: String) -> Completable {
    self.api
      .command(command: "\(cmd) \(url.shellEscapedPath)")
      .subscribe(on: self.scheduler)
  }

  private func neoVimWindow(
    for window: RxNeovimApi.Window,
    currentWindow: RxNeovimApi.Window?,
    currentBuffer: RxNeovimApi.Buffer?
  ) -> Single<NvimView.Window> {
    self.api
      .winGetBuf(window: window)
      .flatMap { buf in self.neoVimBuffer(for: buf, currentBuffer: currentBuffer) }
      .map { buffer in NvimView.Window(
        apiWindow: window,
        buffer: buffer,
        isCurrentInTab: window == currentWindow
      ) }
  }

  private func neoVimTab(
    for tabpage: RxNeovimApi.Tabpage,
    currentTabpage: RxNeovimApi.Tabpage?,
    currentBuffer: RxNeovimApi.Buffer?
  ) -> Single<NvimView.Tabpage> {
    Single.zip(
      self.api.tabpageGetWin(tabpage: tabpage),
      self.api.tabpageListWins(tabpage: tabpage)
    ) { (curWin: $0, wins: $1) }
      .map { tuple in
        tuple.wins.map { win in
          self.neoVimWindow(for: win, currentWindow: tuple.curWin, currentBuffer: currentBuffer)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .map { wins in
        NvimView.Tabpage(apiTabpage: tabpage, windows: wins, isCurrent: tabpage == currentTabpage)
      }
  }
}
