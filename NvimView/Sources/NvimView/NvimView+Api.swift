/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import NvimApi
import PureLayout
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
    Single.create {
      await (
        try? self
          .api.nvimGetMode()
          .map { dict in dict["blocking"]?.boolValue ?? false }
          .get()
      ) ?? false
    }
  }

  func hasDirtyBuffers() -> Single<Bool> {
    Single.create {
      let result = await self.api
        .nvimExecLua(code: """
        local buffers = vim.fn.getbufinfo({bufmodified = true})
        return #buffers > 0
        """, args: [])

      switch result {
      case let .success(value):
        guard let bool = value.boolValue else {
          throw NvimApi.Error.exception(message: "Could not convert values into boolean.")
        }
        return bool
      case let .failure(error):
        throw error
      }
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
    Single.create {
      let result = await self.api.nvimGetCurrentBuf()

      switch result {
      case let .success(value):
        return value
      case let .failure(error):
        throw error
      }
    }
    .flatMap { [weak self] in
      guard let single = self?.neoVimBuffer(for: $0, currentBuffer: $0) else {
        throw NvimApi.Error.exception(message: "Could not get buffer")
      }
      return single
    }
    .subscribe(on: self.scheduler)
  }

  func allBuffers() -> Single<[NvimView.Buffer]> {
    Single.create {
      let (curBuf, bufs) = await (self.api.nvimGetCurrentBuf(), self.api.nvimListBufs())
      return try (curBuf: curBuf.get(), bufs: bufs.get())
    }
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
    Single.create {
      let (curBuf, curTab, tabs) = await (
        self.api.nvimGetCurrentBuf(),
        self.api.nvimGetCurrentTabpage(),
        self.api.nvimListTabpages()
      )

      return try (curBuf: curBuf.get(), curTab: curTab.get(), tabs: tabs.get())
    }
    .map { [weak self] tuple in
      tuple.tabs.compactMap { tab in
        self?.neoVimTab(for: tab, currentTabpage: tuple.curTab, currentBuffer: tuple.curBuf)
      }
    }
    .flatMap(Single.fromSinglesToSingleOfArray)
    .subscribe(on: self.scheduler)
  }

  func newTab() -> Completable {
    Single.create { await self.api.nvimCommand(command: "tabe") }
      .asCompletable()
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
              return Single
                .create { await self?.api.nvimSetCurrentWin(window: NvimApi.Window(win.handle)) }
                .asCompletable()
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
          guard let self else {
            throw NvimApi.Error.exception(message: "Could not set current win")
          }
          return Single.create { await self.api.nvimSetCurrentWin(window: .init(win.handle)) }
            .asCompletable()
        }

        guard let self else {
          throw NvimApi.Error.exception(message: "Could tab sb")
        }
        return Single.create { await self.api.nvimCommand(command: "tab sb \(buffer.handle)") }
          .asCompletable()
      }
      .subscribe(on: self.scheduler)
  }

  func goTo(line: Int) -> Completable {
    Single.create { await self.api.nvimCommand(command: "\(line)") }
      .asCompletable()
      .subscribe(on: self.scheduler)
  }

  /// Closes the current window.
  func closeCurrentTab() -> Completable {
    Single.create { await self.api.nvimCommand(command: "q") }.asCompletable()
      .subscribe(on: self.scheduler)
  }

  func saveCurrentTab() -> Completable {
    Single.create { await self.api.nvimCommand(command: "w") }.asCompletable()
      .subscribe(on: self.scheduler)
  }

  func saveCurrentTab(url: URL) -> Completable {
    Single.create { await self.api.nvimCommand(command: "w \(url.shellEscapedPath)") }
      .asCompletable()
      .subscribe(on: self.scheduler)
  }

  func closeCurrentTabWithoutSaving() -> Completable {
    Single.create { await self.api.nvimCommand(command: "q!") }.asCompletable()
      .subscribe(on: self.scheduler)
  }

  func quitNeoVimWithoutSaving() -> Completable {
    Single.create { await self.api.nvimCommand(command: "qa!") }.asCompletable()
      .subscribe(on: self.scheduler)
  }

  func vimOutput(of command: String) -> Single<String> {
    Single.create {
      let result = await self.api.nvimExec2(src: command, opts: ["output": true])
      switch result {
      case let .success(value): return value
      case let .failure(error): throw error
      }
    }
    .map {
      retval in
      guard let output_value = retval["output"] ?? retval["output"],
            let output = output_value.stringValue
      else { throw NvimApi.Error.exception(message: "Could not convert values to output.") }
      return output
    }
    .subscribe(on: self.scheduler)
  }

  func cursorGo(to position: Position) -> Completable {
    Single.create {
      await self.api.nvimGetCurrentWin()
        .tryFlatAsyncMap { curWin async throws(NvimApi.Error) -> Result<Void, NvimApi.Error> in
          await self.api.nvimWinSetCursor(window: curWin, pos: [position.row, position.column])
        }
    }
    .asCompletable()
    .subscribe(on: self.scheduler)
  }

  func didBecomeMain() -> Completable {
    self.focusGained(true)
  }

  func didResignMain() -> Completable {
    self.focusGained(false)
  }

  internal func neoVimBuffer(
    for buf: NvimApi.Buffer,
    currentBuffer: NvimApi.Buffer?
  ) -> Single<NvimView.Buffer> {
    Single.create {
      let result = await self.api.nvimExecLua(code: """
      local info = vim.fn.getbufinfo(...)[1]
      local result = {}
      result.name = info.name
      result.changed = info.changed
      result.listed = info.listed
      result.buftype = vim.api.nvim_get_option_value("buftype", {buf=info.bufnr})
      return result
      """, args: [MessagePackValue(buf.handle)])
      switch result {
      case let .success(value): return value
      case let .failure(error): throw error
      }
    }
    .map { result -> NvimView.Buffer in
      guard let raw_info = result.dictionaryValue
      else {
        throw NvimApi.Error
          .exception(message: "Could not convert values into info dictionary.")
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
        throw NvimApi.Error
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
    Single.create { await self.api.nvimCommand(command: "\(cmd) \(url.shellEscapedPath)") }
      .asCompletable()
      .subscribe(on: self.scheduler)
  }

  private func neoVimWindow(
    for window: NvimApi.Window,
    currentWindow: NvimApi.Window?,
    currentBuffer: NvimApi.Buffer?
  ) -> Single<NvimView.Window> {
    Single.create {
      switch await self.api.nvimWinGetBuf(window: window) {
      case let .success(value): return value
      case let .failure(error): throw error
      }
    }
    .flatMap { [weak self] buf in
      guard let single = self?.neoVimBuffer(for: buf, currentBuffer: currentBuffer) else {
        throw NvimApi.Error.exception(message: "Could not get buffer")
      }

      return single
    }
    .map { buffer in
      NvimView.Window(apiWindow: window, buffer: buffer, isCurrentInTab: window == currentWindow)
    }
  }

  private func neoVimTab(
    for tabpage: NvimApi.Tabpage,
    currentTabpage: NvimApi.Tabpage?,
    currentBuffer: NvimApi.Buffer?
  ) -> Single<NvimView.Tabpage> {
    Single.create {
      let (curWin, wins) = await (
        self.api.nvimTabpageGetWin(tabpage: tabpage),
        self.api.nvimTabpageListWins(tabpage: tabpage)
      )
      return try (curWin: curWin.get(), wins: wins.get())
    }
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

extension PrimitiveSequence where Trait == SingleTrait {
  static func fromSinglesToSingleOfArray(_ singles: [Single<Element>]) -> Single<[Element]> {
    Observable
      .merge(singles.map { $0.asObservable() })
      .toArray()
  }
}
