/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import NvimApi
import PureLayout
import SpriteKit

extension Collection where Element: Sendable {
  func asyncCompactMap<T: Sendable>(
    _ transform: @Sendable (Element) async throws -> T?
  ) async rethrows -> [T] {
    var values = [T]()
    values.reserveCapacity(self.count)

    for element in self {
      if let result = try await transform(element) { values.append(result) }
    }

    return values
  }
}

public extension NvimView {
  func stop() async {
    if self.stopped {
      dlog.debug("Bridge already stopped.")
      return
    }

    self.stopped = true
    self.nvimProc.quit()

    self.apiSync.stop()
    await self.api.stop()

    self.delegate?.nextEvent(.neoVimStopped)
    dlog.debug("Successfully stopped the bridge.")
  }

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

  func isBlocked() async -> Bool {
    guard case let .success(value) = await self.api.nvimGetMode(),
          let result = value["blocking"]?.boolValue
    else { return false }

    return result
  }

  func hasDirtyBuffers() async -> Bool {
    // FIXME: Proper error handling
    guard case let .success(result) = await self.api
      .nvimExecLua(code: """
      local buffers = vim.fn.getbufinfo({bufmodified = true})
      return #buffers > 0
      """, args: []),
      let bool = result.boolValue
    else { return false }

    return bool
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

  func neoVimBufferSync(
    for buf: NvimApi.Buffer,
    currentBuffer: NvimApi.Buffer?
  ) -> NvimView.Buffer? {
    let result = self.apiSync.nvimExecLua(code: """
    local info = vim.fn.getbufinfo(...)[1]
    local result = {}
    result.name = info.name
    result.changed = info.changed
    result.listed = info.listed
    result.buftype = vim.api.nvim_get_option_value("buftype", {buf=info.bufnr})
    return result
    """, args: [MessagePackValue(buf.handle)])

    guard case let .success(value) = result, let raw_info = value.dictionaryValue else {
      return nil
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
    else { return nil }

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

  func neoVimBuffer(
    for buf: NvimApi.Buffer,
    currentBuffer: NvimApi.Buffer?
  ) async -> NvimView.Buffer? {
    let result = await self.api.nvimExecLua(code: """
    local info = vim.fn.getbufinfo(...)[1]
    local result = {}
    result.name = info.name
    result.changed = info.changed
    result.listed = info.listed
    result.buftype = vim.api.nvim_get_option_value("buftype", {buf=info.bufnr})
    return result
    """, args: [MessagePackValue(buf.handle)])

    guard case let .success(value) = result, let raw_info = value.dictionaryValue else {
      return nil
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
    else { return nil }

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

  func currentBufferSync() -> NvimView.Buffer? {
    guard case let .success(value) = self.apiSync.nvimGetCurrentBuf(),
          let buffer = self.neoVimBufferSync(for: value, currentBuffer: value)
    else { return nil }

    return buffer
  }

  func currentBuffer() async -> NvimView.Buffer? {
    guard case let .success(value) = await self.api.nvimGetCurrentBuf(),
          let buffer = await self.neoVimBuffer(for: value, currentBuffer: value)
    else { return nil }

    return buffer
  }

  func allBuffers() async -> [NvimView.Buffer]? {
    let (curBuf, bufs) = await (
      try? self.api.nvimGetCurrentBuf().get(), try? self.api.nvimListBufs().get()
    )
    guard let curBuf, let bufs else { return nil }
    return await bufs.asyncCompactMap { buf in
      await self.neoVimBuffer(for: buf, currentBuffer: curBuf)
    }
  }

  func isCurrentBufferDirty() async -> Bool {
    await self.currentBuffer()?.isDirty ?? false
  }

  func allTabs() async -> [NvimView.Tabpage]? {
    guard let curBuf = try? await self.api.nvimGetCurrentBuf().get(),
          let curTab = try? await self.api.nvimGetCurrentTabpage().get(),
          let tabs = try? await self.api.nvimListTabpages().get()
    else { return nil }

    return await tabs.asyncCompactMap { tab in
      await self.neoVimTab(for: tab, currentTabpage: curTab, currentBuffer: curBuf)
    }
  }

  func newTab() async {
    await self.api.nvimCommand(command: "tabe").cauterize()
  }

  func open(urls: [URL]) async {
    guard let tabs = await self.allTabs() else { return }

    let buffers = tabs.map(\.windows).flatMap(\.self).map(\.buffer)
    let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

    for url in urls {
      let bufExists = buffers.contains { $0.url == url }
      let wins = tabs.map(\.windows).flatMap(\.self)

      if let win = bufExists ? wins.first(where: { win in win.buffer.url == url }) : nil {
        await self.api.nvimSetCurrentWin(window: .init(win.handle)).cauterize()
      }
      if currentBufferIsTransient { await self.open(url, cmd: "e") }
      else { await self.open(url, cmd: "tabe") }
    }
  }

  func openInNewTab(urls: [URL]) async {
    for url in urls {
      await self.open(url, cmd: "tabe")
    }
  }

  func openInCurrentTab(url: URL) async {
    await self.open(url, cmd: "e")
  }

  func openInHorizontalSplit(urls: [URL]) async {
    for url in urls {
      await self.open(url, cmd: "sp")
    }
  }

  func openInVerticalSplit(urls: [URL]) async {
    for url in urls {
      await self.open(url, cmd: "vsp")
    }
  }

  func select(buffer: NvimView.Buffer) async {
    guard let tabs = await self.allTabs() else { return }
    let allWins = tabs.map(\.windows).flatMap(\.self)

    if let win = allWins.first(where: { $0.buffer == buffer }) {
      return await self.api.nvimSetCurrentWin(window: .init(win.handle)).cauterize()
    }

    await self.api.nvimCommand(command: "tab sb \(buffer.handle)").cauterize()
  }

  func goTo(line: Int) async {
    await self.api.nvimCommand(command: "\(line)").cauterize()
  }

  /// Closes the current window.
  func closeCurrentTab() async {
    await self.api.nvimCommand(command: "q").cauterize()
  }

  func saveCurrentTab() async {
    await self.api.nvimCommand(command: "w").cauterize()
  }

  func saveCurrentTab(url: URL) async {
    await self.api.nvimCommand(command: "w \(url.shellEscapedPath)").cauterize()
  }

  func closeCurrentTabWithoutSaving() async {
    await self.api.nvimCommand(command: "q!").cauterize()
  }

  func quitNeoVimWithoutSaving() async {
    await self.api.nvimCommand(command: "qa!").cauterize()
  }

  func vimOutput(of command: String) async -> String? {
    guard case let .success(retval) = await self.api.nvimExec2(
      src: command,
      opts: ["output": true]
    ),
      let output_value = retval["output"] ?? retval["output"],
      let output = output_value.stringValue
    else { return nil }

    return output
  }

  func cursorGo(to position: Position) async {
    guard let curWin = try? await self.api.nvimGetCurrentWin().get() else { return }
    await self.api.nvimWinSetCursor(
      window: curWin, pos: [position.row, position.column], expectsReturnValue: false
    ).cauterize()
  }

  func didBecomeMain() async {
    await self.focusGained(true)
  }

  func didResignMain() async {
    await self.focusGained(false)
  }

  private func neoVimWindow(
    for window: NvimApi.Window,
    currentWindow: NvimApi.Window?,
    currentBuffer: NvimApi.Buffer?
  ) async -> NvimView.Window? {
    guard case let .success(value) = await self.api.nvimWinGetBuf(window: window),
          let result = await self.neoVimBuffer(for: value, currentBuffer: currentBuffer)
    else { return nil }

    return .init(apiWindow: window, buffer: result, isCurrentInTab: window == currentWindow)
  }

  private func neoVimTab(
    for tabpage: NvimApi.Tabpage,
    currentTabpage: NvimApi.Tabpage?,
    currentBuffer: NvimApi.Buffer?
  ) async -> NvimView.Tabpage? {
    guard let curWin = try? await self.api.nvimTabpageGetWin(tabpage: tabpage).get(),
          let wins = try? await self.api.nvimTabpageListWins(tabpage: tabpage).get()
    else { return nil }

    let ws = await wins.asyncCompactMap { win in
      await self.neoVimWindow(for: win, currentWindow: curWin, currentBuffer: currentBuffer)
    }
    return .init(apiTabpage: tabpage, windows: ws, isCurrent: tabpage == currentTabpage)
  }

  private func open(_ url: URL, cmd: String) async {
    await self.api.nvimCommand(command: "\(cmd) \(url.shellEscapedPath)").cauterize()
  }
}
