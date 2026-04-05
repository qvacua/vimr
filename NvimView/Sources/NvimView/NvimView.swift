/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Carbon
import Cocoa
import Commons
import MessagePack
import NvimApi
import os
import SpriteKit
import Tabs
import UniformTypeIdentifiers
import UserNotifications

extension Result {
  var isSuccess: Bool { if case .success = self { true } else { false } }
  var isFailure: Bool { !self.isSuccess }

  func cauterize() {}
}

public struct FontTrait: OptionSet, Sendable {
  public let rawValue: UInt

  public init(rawValue: UInt) { self.rawValue = rawValue }

  static let italic = FontTrait(rawValue: 1 << 0)
  static let bold = FontTrait(rawValue: 1 << 1)
  static let underline = FontTrait(rawValue: 1 << 2)
  static let undercurl = FontTrait(rawValue: 1 << 3)
}

public enum FontSmoothing: String, Codable, CaseIterable, Sendable {
  case systemSetting
  case withFontSmoothing
  case noFontSmoothing
  case noAntiAliasing
}

@MainActor
public protocol NvimViewDelegate: AnyObject, Sendable {
  func isMenuItemKeyEquivalent(_: NSEvent) -> Bool
  func nextEvent(_: NvimView.Event)
}

@MainActor
public final class NvimView: NSView,
  NSUserInterfaceValidations,
  @preconcurrency NSTextInputClient
{
  // MARK: - Public

  public static let rpcEventName = "com.qvacua.NvimView"

  public static let minFontSize = 4.0
  public static let maxFontSize = 128.0

  // NSFont seems to be immutable
  public nonisolated(unsafe) static let defaultFont = NSFont.userFixedPitchFont(ofSize: 12)!

  public static let defaultLinespacing = 1.0
  public static let defaultCharacterspacing = 1.0

  public static let minLinespacing = 0.5
  public static let maxLinespacing = 8.0

  public weak var delegate: NvimViewDelegate?

  public let usesCustomTabBar: Bool
  public let tabBar: TabBar<TabEntry>?

  public var isLeftOptionMeta = false
  public var isRightOptionMeta = false

  public var activateAsciiImInNormalMode = true

  public let uuid = UUID()
  public let api = NvimApi()
  public let apiSync = NvimApiSync()

  public internal(set) var fatalErrorOccurred = false

  public internal(set) var mode: CursorModeShape = .normal
  public internal(set) var modeInfos = [String: ModeInfo]()

  public internal(set) var theme = Theme.default

  public var usesLigatures = false {
    didSet {
      self.drawer.usesLigatures = self.usesLigatures
      self.markForRenderWholeView()
    }
  }

  public var fontSmoothing = FontSmoothing.systemSetting {
    didSet {
      self.markForRenderWholeView()
    }
  }

  public var linespacing: CGFloat {
    get { self._linespacing }

    set {
      guard newValue >= NvimView.minLinespacing, newValue <= NvimView.maxLinespacing else { return }

      self._linespacing = newValue
      self.updateFontMetaData(self._font)
    }
  }

  public var characterspacing: CGFloat {
    get { self._characterspacing }

    set {
      guard newValue >= 0.0 else { return }

      self._characterspacing = newValue
      self.updateFontMetaData(self._font)
    }
  }

  public var font: NSFont {
    get { self._font }

    set {
      // FIXME:
//      if !newValue.fontDescriptor.symbolicTraits.contains(.monoSpace) {
//        self.log.info("\(newValue) is not monospaced.")
//      }

      let size = newValue.pointSize
      guard size >= NvimView.minFontSize, size <= NvimView.maxFontSize else { return }

      self._font = newValue
      self.updateFontMetaData(newValue)

      self.signalRemoteOptionChange(RemoteOption.fromFont(newValue))
    }
  }

  public var cwd: URL {
    get { self._cwd }
    set {
      self.apiSync.nvimSetCurrentDir(dir: newValue.path).cauterize()
    }
  }

  public var defaultCellAttributes: CellAttributes {
    self.cellAttributesCollection.defaultAttributes
  }

  override public var acceptsFirstResponder: Bool { true }

  public internal(set) var currentPosition = Position.beginning

  public init(frame: NSRect, config: Config) {
    self.drawer = AttributesRunDrawer(
      baseFont: self._font,
      linespacing: self._linespacing,
      characterspacing: self._characterspacing,
      usesLigatures: self.usesLigatures
    )
    self.nvimProc = NvimProcess(uuid: self.uuid, config: config)
    self.remoteSocketPath = config.remoteSocketPath
    self.useSocketConnection = config.useSocketConnection

    self.sourceFileUrls = config.sourceFiles

    self.usesCustomTabBar = config.usesCustomTabBar
    if self.usesCustomTabBar {
      self.tabBar = TabBar<TabEntry>(withTheme: .default)
    } else {
      self.tabBar = nil
    }

    self.asciiImSource = TISCopyCurrentASCIICapableKeyboardInputSource().takeRetainedValue()
    self.lastImSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()

    super.init(frame: frame)

    self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])

    self.wantsLayer = true
    self.cellSize = FontUtils.cellSize(
      of: self.font, linespacing: self.linespacing, characterspacing: self.characterspacing
    )

    self.runBridge()

    self.tabBar?.closeHandler = { [weak self] index, _, _ in
      self?.apiSync.nvimCommand(command: "tabclose \(index + 1)").cauterize()
    }
    self.tabBar?.selectHandler = { [weak self] _, tabEntry, _ in
      self?.apiSync.nvimSetCurrentTabpage(tabpage: tabEntry.tabpage).cauterize()
    }
    self.tabBar?.reorderHandler = { [weak self] index, _, entries in
      // I don't know why, but `tabm ${last_index}` does not always work.
      let command = (index == entries.count - 1) ? "tabm" : "tabm \(index)"
      self?.apiSync.nvimCommand(command: command).cauterize()
    }
  }

  override public convenience init(frame rect: NSRect) {
    self.init(
      frame: rect,
      config: Config(
        usesCustomTabBar: true,
        useInteractiveZsh: false,
        cwd: URL(fileURLWithPath: NSHomeDirectory()),
        nvimBinary: "",
        nvimArgs: nil,
        additionalEnvs: [:],
        sourceFiles: []
      )
    )
  }

  @available(*, unavailable)
  public required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Internal

  let logger = Logger(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.view)

  let queue = DispatchQueue(
    label: String(reflecting: NvimView.self),
    qos: .userInteractive,
    target: .global(qos: .userInteractive)
  )

  let nvimProc: NvimProcess

  let ugrid = UGrid()
  let cellAttributesCollection = CellAttributesCollection()
  let drawer: AttributesRunDrawer
  var baselineOffset = 0.0

  /// We store the last marked text because Cocoa's text input system does the following:
  /// 하 -> hanja popup -> insertText(하) -> attributedSubstring...() -> setMarkedText(下) -> ...
  /// We want to return "하" in attributedSubstring...()
  var lastMarkedText: String?

  var keyDownDone = true

  var lastClickedCellPosition = Position.null

  var offset = CGPoint.zero
  var cellSize = CGSize.zero

  var scrollGuardCounterX = 5
  var scrollGuardCounterY = 5

  var trackpadScrollDeltaX = 0.0
  var trackpadScrollDeltaY = 0.0

  var isCurrentlyPinching = false
  var pinchTargetScale = 1.0
  var pinchBitmap: NSBitmapImageRep?

  var currentlyResizing = false

  var _font = NvimView.defaultFont
  var _cwd = URL(fileURLWithPath: NSHomeDirectory())

  // FIXME: Use self.tabEntries
  // cache the tabs for Touch Bar use
  var tabsCache = [NvimView.Tabpage]()

  var markedText: String?

  let sourceFileUrls: [URL]
  let remoteSocketPath: String?
  let useSocketConnection: Bool

  var tabEntries = [TabEntry]()

  var asciiImSource: TISInputSource
  var lastImSource: TISInputSource

  var lastMode = CursorModeShape.normal

  var regionsToFlush = [Region]()

  var framerateView: SKView?

  var stopped = false

  func dieWithFatalError(description: String) {
    self.logger.fault("Fatal error occurred: \(description)")
    self.fatalErrorOccurred = true
    self.delegate?.nextEvent(.ipcBecameInvalid(description))
  }

  func updateLayerBackgroundColor() {
    self.layer?.backgroundColor = ColorUtils.cgColorIgnoringAlpha(
      self.cellAttributesCollection.defaultAttributes.background
    )
  }

  // MARK: - Private

  private var _linespacing = NvimView.defaultLinespacing
  private var _characterspacing = NvimView.defaultCharacterspacing
  
  private func runBridge() {
    Task(priority: .high) {
      let size = self.discreteSize(size: frame.size)

      if let socketPath = self.remoteSocketPath {
        await self.connectToRunningNvim(address: socketPath, size: size)
      } else if self.useSocketConnection {
        await self.launchNvimAndConnectViaSocket(size)
      } else {
        await self.launchNvim(size)
      }

      let stream = await self.api.msgpackRawStream
      for await msg in stream {
        switch msg {
        case let .request(msgid, method, _):
          // See https://neovim.io/doc/user/ui.html#ui-startup
          // "vimenter" RPC request will be sent to us
          // which is the result of
          // nvim_command("autocmd VimEnter * call rpcrequest(1, 'vimenter')") in
          // NvimView+Resize.swift
          // This is the only request sent from Neovim to the UI, afaics.
          guard method == NvimAutoCommandEvent.vimenter.rawValue else { break }
          dlog.debug("Processing blocking vimenter request")
          await self.doSetupForVimenterAndSendResponse(forMsgid: msgid)

          let serverName = self.nvimProc.pipeUrl.path
          do {
            try self.apiSync.run(socketPath: serverName)
            dlog.debug("Sync API running on \(serverName)")
          } catch {
            self.dieWithFatalError(description: "Could not run sync Nvim API: \(error)")
            return
          }

          self.delegate?.nextEvent(.nvimReady)

          self.setFrameSize(self.bounds.size)

        case let .notification(method, params):
          if method == NvimView.rpcEventName {
            self.delegate?.nextEvent(.rpcEvent(params))
          }

          if method == "redraw" {
            self.renderData(params)
          } else if method == "autocommand" {
            await self.autoCommandEvent(params)
          } else {
            self.logger.error("MSG ERROR: \(msg)")
          }

        case let .error(_, msg):
          self.logger.error("MSG ERROR: \(msg)")

        case let .response(_, error, _):
          guard let array = error.arrayValue,
                array.count >= 2,
                array[0].uint64Value == NvimApi.Error.exceptionRawValue,
                let errorMsg = array[1].stringValue else { return }

          // FIXME:
          if errorMsg.contains("Vim(tabclose):E784") {
            self.delegate?.nextEvent(.warning(.cannotCloseLastTab))
          }
          if errorMsg.starts(with: "Vim(tabclose):E37") {
            self.delegate?.nextEvent(.warning(.noWriteSinceLastChange))
          }
        }
      }

      await self.stop()
    }
  }

  // MARK: - Shared Nvim Setup

  /// Lua chunk that defines the GetHiColor helper and sets vim.g.gui_vimr.
  /// Used by all connection modes before any autocmds are registered.
  /// Takes no args (called with `...` = empty).
  private static let preambleLua = """
    vim.g.gui_vimr = 1
    _G.GetHiColor = function(hlID, component)
      local color = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(hlID)), component)
      if color == nil or color == '' then return -1 end
      return tonumber(color:sub(2), 16) or -1
    end
    """

  /// Lua chunk that registers all autocmds VimR needs.
  /// Receives the RPC channel as the first vararg (`select(1, ...)`).
  /// Separated from the preamble so that pipe mode can register these
  /// during vimenter (after the blocking rpcrequest handshake) without
  /// double-registering.
  private static let autocmdLua = """
    local ch = select(1, ...)
    local augroup = vim.api.nvim_create_augroup('VimRBridge', { clear = true })
    vim.api.nvim_create_autocmd('VimLeave', {
      group = augroup,
      callback = function() vim.rpcnotify(ch, 'autocommand', 'vimleave') end,
    })
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = augroup,
      callback = function()
        vim.rpcnotify(ch, 'autocommand', 'colorscheme',
          GetHiColor('Normal', 'fg'), GetHiColor('Normal', 'bg'),
          GetHiColor('Visual', 'fg'), GetHiColor('Visual', 'bg'),
          GetHiColor('Directory', 'fg'),
          GetHiColor('TablineFill', 'bg'), GetHiColor('TablineFill', 'fg'),
          GetHiColor('Tabline', 'bg'), GetHiColor('Tabline', 'fg'),
          GetHiColor('TablineSel', 'bg'), GetHiColor('TablineSel', 'fg'))
      end,
    })
    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = augroup,
      callback = function(ev) vim.rpcnotify(ch, 'autocommand', 'bufwinenter', ev.buf) end,
    })
    vim.api.nvim_create_autocmd('BufWinLeave', {
      group = augroup,
      callback = function(ev) vim.rpcnotify(ch, 'autocommand', 'bufwinleave', ev.buf) end,
    })
    vim.api.nvim_create_autocmd('TabEnter', {
      group = augroup,
      callback = function(ev) vim.rpcnotify(ch, 'autocommand', 'tabenter', ev.buf) end,
    })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = augroup,
      callback = function(ev) vim.rpcnotify(ch, 'autocommand', 'bufwritepost', ev.buf) end,
    })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = augroup,
      callback = function(ev) vim.rpcnotify(ch, 'autocommand', 'bufenter', ev.buf) end,
    })
    vim.api.nvim_create_autocmd('DirChanged', {
      group = augroup,
      callback = function(ev) vim.rpcnotify(ch, 'autocommand', 'dirchanged', ev.file) end,
    })
    vim.api.nvim_create_autocmd('BufModifiedSet', {
      group = augroup,
      callback = function(ev)
        local info = vim.fn.getbufinfo(ev.buf)
        local changed = info and info[1] and info[1].changed or 0
        vim.rpcnotify(ch, 'autocommand', 'bufmodifiedset', ev.buf, changed)
      end,
    })
    """

  /// Gets the API channel, verifies the nvim version, returns the channel number.
  private func getChannelAndVerifyVersion() async throws -> Int32 {
    let apiInfo = try await self.api.nvimGetApiInfo(errWhenBlocked: false).get()
    guard apiInfo.count == 2,
          let channel = apiInfo[0].int32Value,
          let dict = apiInfo[1].dictionaryValue,
          let version = dict["version"]?.dictionaryValue,
          let major = version["major"]?.intValue,
          let minor = version["minor"]?.intValue,
          major > kMinMajorVersion || (major == kMinMajorVersion && minor >= kMinMinorVersion)
    else {
      throw NvimApi.Error.exception(message: "Error matching API version")
    }
    return channel
  }

  /// Runs the shared autocmd/subscription/source setup that all connection modes need.
  /// In pipe mode this is called during the vimenter handshake (after the preamble was
  /// already exec'd by launchNvim). In socket modes it is called directly.
  private func runCommonNvimSetup(channel: Int32, includePreamble: Bool) async throws {
    if includePreamble {
      _ = try await self.api.nvimExecLua(
        code: Self.preambleLua, args: [], errWhenBlocked: false
      ).get()
    }

    _ = try await self.api.nvimExecLua(
      code: Self.autocmdLua, args: [.int(Int64(channel))], errWhenBlocked: false
    ).get()
    dlog.debug("Nvim setup Lua exec'ed (preamble=\(includePreamble))")

    _ = try await self.api
      .nvimSubscribe(event: NvimView.rpcEventName, expectsReturnValue: false).get()

    for url in self.sourceFileUrls {
      _ = try await self.api.nvimExecLua(
        code: "vim.cmd.source(select(1, ...))",
        args: [.string(url.path)],
        errWhenBlocked: false
      ).get()
    }

    let ginitVimPath = FileManager.default
      .homeDirectoryForCurrentUser
      .appendingPathComponent(".config/nvim/ginit.vim").path
    let ginitLuaPath = FileManager.default
      .homeDirectoryForCurrentUser
      .appendingPathComponent(".config/nvim/ginit.lua").path
    if FileManager.default.fileExists(atPath: ginitLuaPath) {
      dlog.debug("Source'ing ginit.lua")
      _ = try await self.api.nvimExecLua(
        code: "vim.cmd.source(select(1, ...))",
        args: [.string(ginitLuaPath)],
        errWhenBlocked: false
      ).get()
    } else if FileManager.default.fileExists(atPath: ginitVimPath) {
      dlog.debug("Source'ing ginit.vim")
      _ = try await self.api.nvimExecLua(
        code: "vim.cmd.source(select(1, ...))",
        args: [.string(ginitVimPath)],
        errWhenBlocked: false
      ).get()
    }
  }

  /// Attaches the UI to neovim at the given grid size.
  private func attachUi(width: Int, height: Int) async throws {
    _ = try await self.api
      .nvimUiAttach(width: width, height: height, options: [
        "ext_linegrid": true,
        "ext_multigrid": false,
        "ext_tabline": MessagePackValue(self.usesCustomTabBar),
        "rgb": true,
      ]).get()
    dlog.debug("UI attached")
  }

  // MARK: - Connection Modes

  /// Connect to an already-running neovim instance via Unix socket or TCP.
  /// Accepts a socket path (e.g. "/tmp/nvim.sock") or host:port (e.g. "localhost:6666").
  private func connectToRunningNvim(address: String, size: Size) async {
    dlog.debug("Connecting to running Nvim at \(address)")

    do {
      try await self.api.run(address: address)
      try self.apiSync.run(address: address)
      dlog.debug("Both async and sync APIs connected to \(address)")

      let channel = try await self.getChannelAndVerifyVersion()
      dlog.debug("Remote Nvim version OK")

      try await self.runCommonNvimSetup(channel: channel, includePreamble: true)
      try await self.attachUi(width: size.width, height: size.height)

      // In socket/headless mode, nvim has already sourced init.vim before we
      // connected, so the ColorScheme autocmd fired before our rpcnotify was
      // registered. Re-applying the active colorscheme causes nvim to re-emit
      // hl_attr_define + default_colors_set + our ColorScheme rpcnotify so that
      // VimR's Theme and cell colors are correctly populated.
      _ = try await self.api.nvimExecLua(
        code: "vim.cmd.colorscheme(vim.g.colors_name or 'default')",
        args: [],
        errWhenBlocked: false
      ).get()

      self.delegate?.nextEvent(.nvimReady)
      self.setFrameSize(self.bounds.size)
    } catch {
      self.dieWithFatalError(
        description: "Could not connect to remote Nvim at \(address): \(error)"
      )
      return
    }

    dlog.debug("Connected to running Nvim")
  }

  /// Launch a local nvim with --listen, then connect via socket (no stdio pipes).
  private func launchNvimAndConnectViaSocket(_ size: Size) async {
    dlog.debug("Starting Nvim (socket-launch mode)")

    do {
      try self.nvimProc.runLocalServerHeadless()
    } catch {
      self.dieWithFatalError(description: "Could not launch Nvim: \(error)")
      return
    }

    // Give nvim a moment to create the socket
    let socketPath = self.nvimProc.pipeUrl.path
    for _ in 0..<50 {
      if FileManager.default.fileExists(atPath: socketPath) { break }
      try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }

    await self.connectToRunningNvim(address: socketPath, size: size)
    dlog.debug("Launched Nvim (socket-launch mode)")
  }

  /// Handles the blocking "vimenter" rpcrequest during the embedded pipe startup sequence.
  /// The preamble (GetHiColor etc) was already exec'd by launchNvim(), so we only
  /// register the autocmds and do subscribe/source/ginit here.
  private func doSetupForVimenterAndSendResponse(forMsgid msgid: UInt32) async {
    do {
      let channel = try await self.getChannelAndVerifyVersion()
      try await self.runCommonNvimSetup(channel: channel, includePreamble: false)
      _ = try await self.api.sendResponse(.nilResponse(msgid)).get()
    } catch {
      self.dieWithFatalError(description: "Could not set up vimenter event: \(error)")
    }
  }

  /// Classic mode: spawn nvim with --embed, communicate via stdio pipes.
  private func launchNvim(_ size: Size) async {
    dlog.debug("Starting Nvim")

    let inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe
    do {
      (inPipe, outPipe, errorPipe) = try self.nvimProc.runLocalServerAndNvim(
        width: size.width, height: size.height
      )
    } catch {
      self.dieWithFatalError(description: "Could not launch Nvim: \(error)")
      return
    }

    do {
      // See https://neovim.io/doc/user/ui.html#ui-startup for startup sequence
      // When we call nvim_command("autocmd VimEnter * call rpcrequest(1, 'vimenter')")
      // Neovim will send us a vimenter request and enter a blocking state.
      // We do some autocmd setup and send a response to exit the blocking state in
      // the vimenter handler in runBridge().
      try await self.api.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)
      let channel = try await self.getChannelAndVerifyVersion()
      dlog.debug("Version fine")

      // Only the preamble and VimEnter hooks here. The full autocmd set is
      // registered later in doSetupForVimenterAndSendResponse() when the
      // blocking rpcrequest arrives.
      _ = try await self.api.nvimExecLua(
        code: Self.preambleLua, args: [], errWhenBlocked: false
      ).get()
      _ = try await self.api.nvimExecLua(
        code: """
          local ch = select(1, ...)
          local augroup = vim.api.nvim_create_augroup('VimRBridge', { clear = true })
          vim.api.nvim_create_autocmd('VimEnter', {
            group = augroup, once = true,
            callback = function() vim.rpcnotify(ch, 'autocommand', 'vimenter') end,
          })
          vim.api.nvim_create_autocmd('VimEnter', {
            group = augroup, once = true,
            callback = function() vim.rpcrequest(ch, 'vimenter') end,
          })
          """,
        args: [.int(Int64(channel))],
        errWhenBlocked: false
      ).get()
      dlog.debug("Initial Lua exec'ed")

      try await self.attachUi(width: size.width, height: size.height)
    } catch {
      self.dieWithFatalError(
        description: "Could not attach UI and exec initial setup script: \(error)"
      )
      return
    }

    dlog.debug("Launched Nvim")
  }
}
