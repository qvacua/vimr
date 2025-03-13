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

  func tryAsyncMap<NewSuccess>(
    _ transform: @Sendable (Success) async throws(Failure) -> NewSuccess
  ) async -> Result<NewSuccess, Failure> {
    switch self {
    case let .success(success):
      do {
        return try await .success(transform(success))
      } catch {
        return .failure(error)
      }
    case let .failure(failure):
      return .failure(failure)
    }
  }

  func tryFlatAsyncMap<NewSuccess>(
    _ transform: @Sendable (Success) async throws(Failure) -> Result<NewSuccess, Failure>
  ) async -> Result<NewSuccess, Failure> {
    switch self {
    case let .success(success):
      do {
        return try await transform(success)
      } catch {
        return .failure(error)
      }
    case let .failure(failure):
      return .failure(failure)
    }
  }
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
  func nextEvent(_: NvimView.Event) async
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
    didSet { self.markForRenderWholeView() }
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
      if !newValue.fontDescriptor.symbolicTraits.contains(.monoSpace) {
        self.log.info("\(newValue) is not monospaced.")
      }

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
      Task {
        // FIXME: Error handling?
        await self.api.nvimSetCurrentDir(dir: newValue.path).cauterize()
      }
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
    self.bridge = UiBridge(uuid: self.uuid, config: config)

    self.sourceFileUrls = config.sourceFiles

    self.usesCustomTabBar = config.usesCustomTabBar
    if self.usesCustomTabBar { self.tabBar = TabBar<TabEntry>(withTheme: .default) }
    else { self.tabBar = nil }

    self.asciiImSource = TISCopyCurrentASCIICapableKeyboardInputSource().takeRetainedValue()
    self.lastImSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()

    super.init(frame: frame)

    self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])

    self.wantsLayer = true
    self.cellSize = FontUtils.cellSize(
      of: self.font, linespacing: self.linespacing, characterspacing: self.characterspacing
    )

    Task(priority: .high) {
      await self.launchNvim(self.discreteSize(size: frame.size))

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
          self.log.debug("Processing blocking vimenter request")
          await self.doSetupForVimenterAndSendResponse(forMsgid: msgid)

          do {
            guard let serverName = try await self.api.nvimGetVvar(name: "servername").get()
              .stringValue
            else {
              throw NvimApi.Error.other(description: "v:servername value is nil")
            }
            try self.apiSync.run(socketPath: serverName)
            self.log.debug("Sync API running on \(serverName)")
          } catch {
            await self.dieWithFatalError(description: "Could not run sync Nvim API: \(error)")
            return
          }

          self.setFrameSize(self.bounds.size)

        case let .notification(method, params):
          if method == NvimView.rpcEventName {
            await self.delegate?.nextEvent(.rpcEvent(params))
          }

          if method == "redraw" {
            self.renderData(params)
          } else if method == "autocommand" {
            await self.autoCommandEvent(params)
          } else {
            self.log.debug("MSG ERROR: \(msg)")
          }

        case let .error(_, msg):
          self.log.debug("MSG ERROR: \(msg)")

        case let .response(_, error, _):
          guard let array = error.arrayValue,
                array.count >= 2,
                array[0].uint64Value == NvimApi.Error.exceptionRawValue,
                let errorMsg = array[1].stringValue else { return }

          // FIXME:
          if errorMsg.contains("Vim(tabclose):E784") {
            await self.delegate?.nextEvent(.warning(.cannotCloseLastTab))
          }
          if errorMsg.starts(with: "Vim(tabclose):E37") {
            await self.delegate?.nextEvent(.warning(.noWriteSinceLastChange))
          }
        }
      }

      await self.stop()
    }

    // FIXME: Make callbacks async
    self.tabBar?.closeHandler = { [weak self] index, _, _ in
      Task { await self?.api.nvimCommand(command: "tabclose \(index + 1)") }
    }
    self.tabBar?.selectHandler = { [weak self] _, tabEntry, _ in
      Task { await self?.api.nvimSetCurrentTabpage(tabpage: tabEntry.tabpage) }
    }
    self.tabBar?.reorderHandler = { [weak self] index, _, entries in
      Task {
        // I don't know why, but `tabm ${last_index}` does not always work.
        let command = (index == entries.count - 1) ? "tabm" : "tabm \(index)"
        return await self?.api.nvimCommand(command: command)
      }
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
        envDict: nil,
        sourceFiles: []
      )
    )
  }

  @available(*, unavailable)
  public required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Internal

  let queue = DispatchQueue(
    label: String(reflecting: NvimView.self),
    qos: .userInteractive,
    target: .global(qos: .userInteractive)
  )

  let bridge: UiBridge

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
  let bridgeLogger = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.bridge)
  let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.view)

  let sourceFileUrls: [URL]

  var tabEntries = [TabEntry]()

  var asciiImSource: TISInputSource
  var lastImSource: TISInputSource

  var lastMode = CursorModeShape.normal

  var regionsToFlush = [Region]()

  var framerateView: SKView?

  var stopped = false

  func dieWithFatalError(description: String) async {
    self.log.fault("Fatal error occurred: \(description)")
    self.fatalErrorOccurred = true
    await self.delegate?.nextEvent(.ipcBecameInvalid(description))
  }

  // MARK: - Private

  private var _linespacing = NvimView.defaultLinespacing
  private var _characterspacing = NvimView.defaultCharacterspacing

  private func doSetupForVimenterAndSendResponse(forMsgid msgid: UInt32) async {
    do {
      let apiInfoValue = try await self.api.nvimGetApiInfo(errWhenBlocked: false).get()
      guard let apiInfo = apiInfoValue.arrayValue,
            apiInfo.count == 2,
            let channel = apiInfo[0].int32Value
      else {
        throw NvimApi.Error.exception(message: "Error matching API version")
      }

      // swiftformat:disable all
      _ = try await self.api.nvimExec2(src: """
      autocmd BufWinEnter * call rpcnotify(\(channel), 'autocommand', 'bufwinenter', str2nr(expand('<abuf>')))
      autocmd BufWinLeave * call rpcnotify(\(channel), 'autocommand', 'bufwinleave', str2nr(expand('<abuf>')))
      autocmd TabEnter * call rpcnotify(\(channel), 'autocommand', 'tabenter', str2nr(expand('<abuf>')))
      autocmd BufWritePost * call rpcnotify(\(channel), 'autocommand', 'bufwritepost', str2nr(expand('<abuf>')))
      autocmd BufEnter * call rpcnotify(\(channel), 'autocommand', 'bufenter', str2nr(expand('<abuf>')))
      autocmd DirChanged * call rpcnotify(\( channel), 'autocommand', 'dirchanged', expand('<afile>'))
      autocmd BufModifiedSet * call rpcnotify(\(channel), 'autocommand', 'bufmodifiedset', str2nr(expand('<abuf>')), getbufinfo(str2nr(expand('<abuf>')))[0].changed)
      """, opts: [:], errWhenBlocked: false).get()
      // swiftformat:enable all

      _ = try await self.api
        .nvimSubscribe(event: NvimView.rpcEventName, expectsReturnValue: false).get()

      for url in self.sourceFileUrls {
        _ = try await self.api
          .nvimExec2(
            src: "source \(url.shellEscapedPath)",
            opts: [:],
            errWhenBlocked: false
          ).get()
      }
      _ = try await self.api.sendResponse(.nilResponse(msgid)).get()

      let ginitPath = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/nvim/ginit.vim").path
      if FileManager.default.fileExists(atPath: ginitPath) {
        self.bridgeLogger.debug("Source'ing ginit.vim")
        _ = try await self.api.nvimCommand(command: "source \(ginitPath.shellEscapedPath)").get()
      }
    } catch {
      await self.dieWithFatalError(description: "Could not set up vimenter event: \(error)")
    }
  }

  private func launchNvim(_ size: Size) async {
    self.log.info("=== Starting Nvim...")

    let inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe
    do {
      (inPipe, outPipe, errorPipe) = try self.bridge.runLocalServerAndNvim(
        width: size.width, height: size.height
      )
    } catch {
      await self.dieWithFatalError(description: "Could not launch Nvim: \(error)")
      return
    }

    do {
      // See https://neovim.io/doc/user/ui.html#ui-startup for startup sequence
      // When we call nvim_command("autocmd VimEnter * call rpcrequest(1, 'vimenter')")
      // Neovim will send us a vimenter request and enter a blocking state.
      // We do some autocmd setup and send a response to exit the blocking state in
      // NvimView.swift
      try await self.api.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)
      let apiInfoValue = try await self.api.nvimGetApiInfo(errWhenBlocked: false).get()
      guard let apiInfo = apiInfoValue.arrayValue,
            apiInfo.count == 2,
            let channel = apiInfo[0].int32Value,
            let dict = apiInfo[1].dictionaryValue,
            let version = dict["version"]?.dictionaryValue,
            let major = version["major"]?.intValue,
            let minor = version["minor"]?.intValue,
            major > kMinMajorVersion || (major == kMinMajorVersion && minor >= kMinMinorVersion)
      else {
        throw NvimApi.Error.exception(message: "Error matching API version")
      }

      self.log.debug("Version fine")

      // swiftformat:disable all
      let vimscript = """
        function! GetHiColor(hlID, component)
          let color = synIDattr(synIDtrans(hlID(a:hlID)), a:component)
          if empty(color)
            return -1
          else
            return str2nr(color[1:], 16)
          endif
        endfunction
        let g:gui_vimr = 1
        autocmd VimLeave * call rpcnotify(\(channel), 'autocommand', 'vimleave')
        autocmd VimEnter * call rpcnotify(\(channel), 'autocommand', 'vimenter')
        autocmd ColorScheme * call rpcnotify(\(channel), 'autocommand', 'colorscheme', GetHiColor('Normal', 'fg'), GetHiColor('Normal', 'bg'), GetHiColor('Visual', 'fg'), GetHiColor('Visual', 'bg'), GetHiColor('Directory', 'fg'), GetHiColor('TablineFill', 'bg'), GetHiColor('TablineFill', 'fg'), GetHiColor('Tabline', 'bg'), GetHiColor('Tabline', 'fg'), GetHiColor('TablineSel', 'bg'), GetHiColor('TablineSel', 'fg'))
        autocmd VimEnter * call rpcrequest(\(channel), 'vimenter')
        """
      // swiftformat:enable all

      _ = try await self.api.nvimExec2(src: vimscript, opts: [:], errWhenBlocked: false).get()
      self.log.debug("Initial script exec'ed")

      _ = try await self.api
        .nvimUiAttach(width: size.width, height: size.height, options: [
          "ext_linegrid": true,
          "ext_multigrid": false,
          "ext_tabline": MessagePackValue(self.usesCustomTabBar),
          "rgb": true,
        ]).get()
      self.log.debug("UI attached")
    } catch {
      await self.dieWithFatalError(
        description: "Could not attach UI and exec initial setup script: \(error)"
      )
      return
    }

    self.log.debug("Launched Nvim")
  }
}
