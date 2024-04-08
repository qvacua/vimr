/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Carbon
import Cocoa
import Commons
import MessagePack
import os
import RxNeovim
import RxPack
import RxSwift
import SpriteKit
import Tabs
import UniformTypeIdentifiers
import UserNotifications

public struct FontTrait: OptionSet {
  public let rawValue: UInt

  public init(rawValue: UInt) { self.rawValue = rawValue }

  static let italic = FontTrait(rawValue: 1 << 0)
  static let bold = FontTrait(rawValue: 1 << 1)
  static let underline = FontTrait(rawValue: 1 << 2)
  static let undercurl = FontTrait(rawValue: 1 << 3)
}

public enum FontSmoothing: String, Codable, CaseIterable {
  case systemSetting
  case withFontSmoothing
  case noFontSmoothing
  case noAntiAliasing
}

public protocol NvimViewDelegate: AnyObject {
  func isMenuItemKeyEquivalent(_: NSEvent) -> Bool
}

public final class NvimView: NSView, NSUserInterfaceValidations, NSTextInputClient {
  // MARK: - Public

  public static let rpcEventName = "com.qvacua.NvimView"

  public static let minFontSize = 4.0
  public static let maxFontSize = 128.0
  public static let defaultFont = NSFont.userFixedPitchFont(ofSize: 12)!
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
  public let api = RxNeovimApi()

  public internal(set) var mode: CursorModeShape = .normal
  public internal(set) var modeInfos = [String: ModeInfo]()

  public internal(set) var theme = Theme.default

  public var usesLiveResize = false

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
      self.api
        .setCurrentDir(dir: newValue.path)
        .subscribe(on: self.scheduler)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject
            .onError(Error.ipc(msg: "Could not set cwd to \(newValue)", cause: error))
        })
        .disposed(by: self.disposeBag)
    }
  }

  public var defaultCellAttributes: CellAttributes {
    self.cellAttributesCollection.defaultAttributes
  }

  override public var acceptsFirstResponder: Bool { true }

  public let scheduler: SerialDispatchQueueScheduler

  public internal(set) var currentPosition = Position.beginning

  public var events: Observable<Event> { self.eventsSubject.asObservable() }

  public init(frame _: NSRect, config: Config) {
    self.drawer = AttributesRunDrawer(
      baseFont: self._font,
      linespacing: self._linespacing,
      characterspacing: self._characterspacing,
      usesLigatures: self.usesLigatures
    )
    self.bridge = UiBridge(uuid: self.uuid, config: config)
    self.scheduler = SerialDispatchQueueScheduler(
      queue: self.queue,
      internalSerialQueueName: "com.qvacua.NvimView.NvimView"
    )

    self.sourceFileUrls = config.sourceFiles

    self.usesCustomTabBar = config.usesCustomTabBar
    if self.usesCustomTabBar { self.tabBar = TabBar<TabEntry>(withTheme: .default) }
    else { self.tabBar = nil }

    self.asciiImSource = TISCopyCurrentASCIICapableKeyboardInputSource().takeRetainedValue()
    self.lastImSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()

    super.init(frame: .zero)

    self.api.streamResponses = false
    self.api.msgpackRawStream
      .subscribe(onNext: { [weak self] msg in
        switch msg {
        case let .request(msgid, method, _):
          // See https://neovim.io/doc/user/ui.html#ui-startup
          // "vimenter" RPC request will be sent to us
          // which is the result of
          // nvim_command("autocmd VimEnter * call rpcrequest(1, 'vimenter')") in
          // NvimView+Resize.swift
          // This is the only request sent from Neovim to the UI, afaics.
          guard method == "vimenter" else { break }
          self?.log.debug("Processing blocking vimenter request")
          self?.doSetupForVimenterAndSendResponse(forMsgid: msgid)

        case let .notification(method, params):
          if method == NvimView.rpcEventName {
            self?.eventsSubject.onNext(.rpcEvent(params))
          }

          if method == "redraw" {
            self?.renderData(params)
          } else if method == "autocommand" {
            self?.autoCommandEvent(params)
          } else {
            self?.log.debug("MSG ERROR: \(msg)")
          }

        case let .error(_, msg):
          self?.log.debug("MSG ERROR: \(msg)")

        case let .response(_, error, _):
          guard let array = error.arrayValue,
                array.count >= 2,
                array[0].uint64Value == RxNeovimApi.Error.exceptionRawValue,
                let errorMsg = array[1].stringValue else { return }

          // FIXME:
          if errorMsg.contains("Vim(tabclose):E784") {
            self?.eventsSubject.onNext(.warning(.cannotCloseLastTab))
          }
          if errorMsg.starts(with: "Vim(tabclose):E37") {
            self?.eventsSubject.onNext(.warning(.noWriteSinceLastChange))
          }
        }
      }, onError: { [weak self] error in
        self?.log.error(error)
      }, onCompleted: { [weak self] in
        self?.stop()
      })
      .disposed(by: self.disposeBag)

    let db = self.disposeBag
    self.tabBar?.closeHandler = { [weak self] index, _, _ in
      self?.api
        .command(command: "tabclose \(index + 1)")
        .subscribe()
        .disposed(by: db)
    }
    self.tabBar?.selectHandler = { [weak self] _, tabEntry, _ in
      self?.api
        .setCurrentTabpage(tabpage: tabEntry.tabpage)
        .subscribe()
        .disposed(by: db)
    }
    self.tabBar?.reorderHandler = { [weak self] index, _, entries in
      // I don't know why, but `tabm ${last_index}` does not always work.
      let command = (index == entries.count - 1) ? "tabm" : "tabm \(index)"
      self?.api
        .command(command: command)
        .subscribe()
        .disposed(by: db)
    }

    self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])

    self.wantsLayer = true
    self.cellSize = FontUtils.cellSize(
      of: self.font, linespacing: self.linespacing, characterspacing: self.characterspacing
    )
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
  var currentEmoji = "😎"

  var _font = NvimView.defaultFont
  var _cwd = URL(fileURLWithPath: NSHomeDirectory())
  var isInitialResize = true

  // FIXME: Use self.tabEntries
  // cache the tabs for Touch Bar use
  var tabsCache = [NvimView.Tabpage]()

  let eventsSubject = PublishSubject<Event>()
  let disposeBag = DisposeBag()

  var markedText: String?
  let bridgeLogger = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.bridge)
  let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.view)

  let sourceFileUrls: [URL]

  let nvimExitedCondition = ConditionVariable()

  var tabEntries = [TabEntry]()

  var asciiImSource: TISInputSource
  var lastImSource: TISInputSource

  var lastMode = CursorModeShape.normal

  var regionsToFlush = [Region]()

  var framerateView: SKView?

  // MARK: - Private

  private var _linespacing = NvimView.defaultLinespacing
  private var _characterspacing = NvimView.defaultCharacterspacing

  private func doSetupForVimenterAndSendResponse(forMsgid msgid: UInt32) {
    self.api.getApiInfo(errWhenBlocked: false)
      .flatMapCompletable { value in
        guard let info = value.arrayValue,
              info.count == 2,
              let channel = info[0].int32Value
        else {
          throw RxNeovimApi.Error.exception(message: "Could not convert values to api info.")
        }

        // swiftformat:disable all
        return self.api.exec2(src: """
        autocmd BufWinEnter * call rpcnotify(\(channel), 'autocommand', 'bufwinenter', str2nr(expand('<abuf>')))
        autocmd BufWinLeave * call rpcnotify(\(channel), 'autocommand', 'bufwinleave', str2nr(expand('<abuf>')))
        autocmd TabEnter * call rpcnotify(\(channel), 'autocommand', 'tabenter', str2nr(expand('<abuf>')))
        autocmd BufWritePost * call rpcnotify(\(channel), 'autocommand', 'bufwritepost', str2nr(expand('<abuf>')))
        autocmd BufEnter * call rpcnotify(\(channel), 'autocommand', 'bufenter', str2nr(expand('<abuf>')))
        autocmd DirChanged * call rpcnotify(\( channel), 'autocommand', 'dirchanged', expand('<afile>'))
        autocmd BufModifiedSet * call rpcnotify(\(channel), 'autocommand', 'bufmodifiedset', str2nr(expand('<abuf>')), getbufinfo(str2nr(expand('<abuf>')))[0].changed)
        """, opts: [:], errWhenBlocked: false)
        // swiftformat:enable all
          .asCompletable()
          .andThen(self.api.subscribe(event: NvimView.rpcEventName, expectsReturnValue: false))
          .andThen(
            self.sourceFileUrls.reduce(.empty()) { prev, url in
              prev.andThen(
                self.api.exec2(
                  src: "source \(url.shellEscapedPath)",
                  opts: ["output": true],
                  errWhenBlocked: false
                )
                .map { retval in
                  guard let output = retval["output"]?.stringValue else {
                    throw RxNeovimApi.Error
                      .exception(message: "Could not convert values to output.")
                  }
                  return output
                }
                .asCompletable()
              )
            }
          )
          .andThen(self.api.sendResponse(.nilResponse(msgid)))
          .andThen(
            {
              let ginitPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config/nvim/ginit.vim").path
              guard FileManager.default.fileExists(atPath: ginitPath) else { return .empty() }

              self.bridgeLogger.debug("Source'ing ginit.vim")
              return self.api.command(command: "source \(ginitPath.shellEscapedPath)")
            }()
          )
      }
      .subscribe().disposed(by: self.disposeBag)
  }
}
