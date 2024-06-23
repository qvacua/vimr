/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import PureLayout
import RxNeovim
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
    self.api.nvimGetMode().map { dict in dict["blocking"]?.boolValue ?? false }
  }

  func hasDirtyBuffers() -> Single<Bool> {
    self.api
      .nvimExecLua(code: """
      local buffers = vim.fn.getbufinfo({bufmodified = true})
      return #buffers > 0
      """, args: [])
      .map { result -> Bool in
        guard let bool = result.boolValue else {
          throw RxNeovimApi.Error.exception(message: "Could not convert values into boolean.")
        }
        return bool
      }
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
      .nvimGetCurrentBuf()
      .flatMap { [weak self] in
        guard let single = self?.neoVimBuffer(for: $0, currentBuffer: $0) else {
          throw RxNeovimApi.Error.exception(message: "Could not get buffer")
        }
        return single
      }
      .subscribe(on: self.scheduler)
  }

  func allBuffers() -> Single<[NvimView.Buffer]> {
    Single
      .zip(self.api.nvimGetCurrentBuf(), self.api.nvimListBufs()) { (curBuf: $0, bufs: $1) }
      .map { [weak self] tuple in
        tuple.bufs.compactMap { buf in
          self?.neoVimBuffer(for: buf, currentBuffer: tuple.curBuf)
        }
      }
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
      self.api.nvimGetCurrentBuf(),
      self.api.nvimGetCurrentTabpage(),
      self.api.nvimListTabpages()
    ) { (curBuf: $0, curTab: $1, tabs: $2) }
      .map { [weak self] tuple in
        tuple.tabs.compactMap { tab in
          self?.neoVimTab(for: tab, currentTabpage: tuple.curTab, currentBuffer: tuple.curBuf)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .subscribe(on: self.scheduler)
  }

  func newTab() -> Completable {
    self.api
      .nvimCommand(command: "tabe")
      .subscribe(on: self.scheduler)
  }

  func open(urls: [URL]) -> Completable {
    self
      .allTabs()
      .flatMapCompletable { [weak self] tabs -> Completable in
        let buffers = tabs.map(\.windows).flatMap { $0 }.map(\.buffer)
        let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

        return Completable.concat(
          urls.compactMap { url -> Completable? in
            let bufExists = buffers.contains { $0.url == url }
            let wins = tabs.map(\.windows).flatMap { $0 }
            if let win = bufExists ? wins.first(where: { win in win.buffer.url == url }) : nil {
              return self?.api.nvimSetCurrentWin(window: RxNeovimApi.Window(win.handle))
            }

            return currentBufferIsTransient ? self?.open(url, cmd: "e") : self?
              .open(url, cmd: "tabe")
          }
        )
      }
      .subscribe(on: self.scheduler)
  }

  func openInNewTab(urls: [URL]) -> Completable {
    Completable
      .concat(urls.compactMap { [weak self] url in self?.open(url, cmd: "tabe") })
      .subscribe(on: self.scheduler)
  }

  func openInCurrentTab(url: URL) -> Completable {
    self.open(url, cmd: "e")
  }

  func openInHorizontalSplit(urls: [URL]) -> Completable {
    Completable
      .concat(urls.compactMap { [weak self] url in self?.open(url, cmd: "sp") })
      .subscribe(on: self.scheduler)
  }

  func openInVerticalSplit(urls: [URL]) -> Completable {
    Completable
      .concat(urls.compactMap { [weak self] url in self?.open(url, cmd: "vsp") })
      .subscribe(on: self.scheduler)
  }

  func select(buffer: NvimView.Buffer) -> Completable {
    self
      .allTabs()
      .map { tabs in tabs.map(\.windows).flatMap { $0 } }
      .flatMapCompletable { [weak self] wins -> Completable in
        if let win = wins.first(where: { $0.buffer == buffer }) {
          guard let completable = self?.api
            .nvimSetCurrentWin(window: RxNeovimApi.Window(win.handle))
          else {
            throw RxNeovimApi.Error.exception(message: "Could not set current win")
          }

          return completable
        }

        guard let completable = self?.api.nvimCommand(command: "tab sb \(buffer.handle)") else {
          throw RxNeovimApi.Error.exception(message: "Could tab sb")
        }
        return completable
      }
      .subscribe(on: self.scheduler)
  }

  func goTo(line: Int) -> Completable {
    self.api
      .nvimCommand(command: "\(line)")
      .subscribe(on: self.scheduler)
  }

  /// Closes the current window.
  func closeCurrentTab() -> Completable {
    self.api
      .nvimCommand(command: "q")
      .subscribe(on: self.scheduler)
  }

  func saveCurrentTab() -> Completable {
    self.api
      .nvimCommand(command: "w")
      .subscribe(on: self.scheduler)
  }

  func saveCurrentTab(url: URL) -> Completable {
    self.api
      .nvimCommand(command: "w \(url.shellEscapedPath)")
      .subscribe(on: self.scheduler)
  }

  func closeCurrentTabWithoutSaving() -> Completable {
    self.api
      .nvimCommand(command: "q!")
      .subscribe(on: self.scheduler)
  }

  func quitNeoVimWithoutSaving() -> Completable {
    self.api
      .nvimCommand(command: "qa!")
      .subscribe(on: self.scheduler)
  }

  func vimOutput(of command: String) -> Single<String> {
    self.api
      .nvimExec2(src: command, opts: ["output": true])
      .map {
        retval in
        guard let output_value = retval["output"] ?? retval["output"],
              let output = output_value.stringValue
        else { throw RxNeovimApi.Error.exception(message: "Could not convert values to output.") }
        return output
      }
      .subscribe(on: self.scheduler)
  }

  func cursorGo(to position: Position) -> Completable {
    self.api
      .nvimGetCurrentWin()
      .flatMapCompletable { [weak self] curWin in
        guard let completable = self?.api.nvimWinSetCursor(
          window: curWin,
          pos: [position.row, position.column]
        ) else {
          throw RxNeovimApi.Error.exception(message: "Could not set cursor")
        }

        return completable
      }
      .subscribe(on: self.scheduler)
  }

  func didBecomeMain() -> Completable {
    self.focusGained(true)
  }

  func didResignMain() -> Completable {
    self.focusGained(false)
  }

  internal func neoVimBuffer(
    for buf: RxNeovimApi.Buffer,
    currentBuffer: RxNeovimApi.Buffer?
  ) -> Single<NvimView.Buffer> {
    self.api.nvimExecLua(code: """
    local info = vim.fn.getbufinfo(...)[1]
    local result = {}
    result.name = info.name
    result.changed = info.changed
    result.listed = info.listed
    result.buftype = vim.api.nvim_get_option_value("buftype", {buf=info.bufnr})
    return result
    """, args: [MessagePackValue(buf.handle)])
      .map { result -> NvimView.Buffer in
        guard let raw_info = result.dictionaryValue
        else {
          throw RxNeovimApi.Error.exception(message: "Could not convert values into info dictionary.")
        }
        let info: [String: MessagePackValue] = .init(
          uniqueKeysWithValues: raw_info.map {
            (key: MessagePackValue, value: MessagePackValue) in
            (key.stringValue!, value)
          }
        )

        let current = buf == currentBuffer
        guard let path = info["name"]?.stringValue,
              let dirty = info["changed"]?.intValue,
              let buftype = info["buftype"]?.stringValue,
              let listed = info["listed"]?.intValue
        else {
          throw RxNeovimApi.Error
            .exception(message: "Could not convert values from the dictionary.")
        }

        let url = path == "" || buftype != "" ? nil : URL(fileURLWithPath: path)

        return NvimView.Buffer(
          apiBuffer: buf,
          url: url,
          type: buftype,
          isDirty: dirty != 0,
          isCurrent: current,
          isListed: listed != 0
        )
      }
      .subscribe(on: self.scheduler)
  }

  private func open(_ url: URL, cmd: String) -> Completable {
    self.api
      .nvimCommand(command: "\(cmd) \(url.shellEscapedPath)")
      .subscribe(on: self.scheduler)
  }

  private func neoVimWindow(
    for window: RxNeovimApi.Window,
    currentWindow: RxNeovimApi.Window?,
    currentBuffer: RxNeovimApi.Buffer?
  ) -> Single<NvimView.Window> {
    self.api
      .nvimWinGetBuf(window: window)
      .flatMap { [weak self] buf in
        guard let single = self?.neoVimBuffer(for: buf, currentBuffer: currentBuffer) else {
          throw RxNeovimApi.Error.exception(message: "Could not get buffer")
        }

        return single
      }
      .map { buffer in NvimView.Window(
        apiWindow: window,
        buffer: buffer,
        isCurrentInTab: window == currentWindow
      )
      }
  }

  private func neoVimTab(
    for tabpage: RxNeovimApi.Tabpage,
    currentTabpage: RxNeovimApi.Tabpage?,
    currentBuffer: RxNeovimApi.Buffer?
  ) -> Single<NvimView.Tabpage> {
    Single.zip(
      self.api.nvimTabpageGetWin(tabpage: tabpage),
      self.api.nvimTabpageListWins(tabpage: tabpage)
    ) { (curWin: $0, wins: $1) }
      .map { [weak self] tuple in
        tuple.wins.compactMap { win in
          self?.neoVimWindow(for: win, currentWindow: tuple.curWin, currentBuffer: currentBuffer)
        }
      }
      .flatMap(Single.fromSinglesToSingleOfArray)
      .map { wins in
        NvimView.Tabpage(apiTabpage: tabpage, windows: wins, isCurrent: tabpage == currentTabpage)
      }
  }
}
