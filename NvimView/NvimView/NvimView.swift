/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import MessagePack
import os

public class NvimView: NSView,
                       UiBridgeConsumer,
                       NSUserInterfaceValidations,
                       NSTextInputClient {

  // MARK: - Public
  public static let rpcEventName = "com.qvacua.NvimView"

  public static let minFontSize = 4.cgf
  public static let maxFontSize = 128.cgf
  public static let defaultFont = NSFont.userFixedPitchFont(ofSize: 12)!
  public static let defaultLinespacing = 1.cgf
  public static let defaultCharacterspacing = 1.cgf

  public static let minLinespacing = (0.5).cgf
  public static let maxLinespacing = 8.cgf

  public var isLeftOptionMeta = false
  public var isRightOptionMeta = false

  public let uuid = UUID()
  public let api = RxNeovimApi()

  public internal(set) var mode = CursorModeShape.normal
  public internal(set) var modeInfoList = [ModeInfo]()

  public internal(set) var theme = Theme.default

  public var trackpadScrollResistance = 5.cgf

  public var usesLiveResize = false

  public var usesLigatures = false {
    didSet {
      self.drawer.usesLigatures = self.usesLigatures
      self.markForRenderWholeView()
    }
  }

  public var drawsParallel = false {
    didSet {
      self.drawer.drawsParallel = self.drawsParallel
    }
  }

  public var linespacing: CGFloat {
    get {
      return self._linespacing
    }

    set {
      guard newValue >= NvimView.minLinespacing && newValue <= NvimView.maxLinespacing else {
        return
      }

      self._linespacing = newValue
      self.updateFontMetaData(self._font)
    }
  }

  public var characterspacing: CGFloat {
    get {
      return self._characterspacing
    }

    set {
      guard newValue >= 0.0 else {
        return
      }

      self._characterspacing = newValue
      self.updateFontMetaData(self._font)
    }
  }

  public var font: NSFont {
    get {
      return self._font
    }

    set {
      guard newValue.isFixedPitch else {
        return
      }

      let size = newValue.pointSize
      guard size >= NvimView.minFontSize && size <= NvimView.maxFontSize else {
        return
      }

      self._font = newValue
      self.updateFontMetaData(newValue)
    }
  }

  public var cwd: URL {
    get {
      return self._cwd
    }

    set {
      self.api
        .setCurrentDir(dir: newValue.path)
        .subscribeOn(self.scheduler)
        .subscribe(onError: { error in
          self.eventsSubject.onError(Error.ipc(msg: "Could not set cwd to \(newValue)", cause: error))
        })
        .disposed(by: self.disposeBag)
    }
  }

  public var defaultCellAttributes: CellAttributes {
    self.cellAttributesCollection.defaultAttributes
  }

  override public var acceptsFirstResponder: Bool {
    return true
  }

  public let scheduler: SerialDispatchQueueScheduler

  public internal(set) var currentPosition = Position.beginning

  public var events: Observable<Event> {
    return self.eventsSubject.asObservable()
  }

  public init(frame rect: NSRect, config: Config) {
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

    super.init(frame: .zero)
    self.bridge.consumer = self
    self.registerForDraggedTypes([NSPasteboard.PasteboardType(String(kUTTypeFileURL))])

    self.wantsLayer = true
    self.cellSize = FontUtils.cellSize(
      of: self.font, linespacing: self.linespacing, characterspacing: self.characterspacing
    )
  }

  convenience override public init(frame rect: NSRect) {
    self.init(
      frame: rect,
      config: Config(
        useInteractiveZsh: false,
        cwd: URL(fileURLWithPath: NSHomeDirectory()),
        nvimArgs: nil,
        envDict: nil,
        sourceFiles: []
      )
    )
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction public func debug1(_ sender: Any?) {
    #if DEBUG
    do { try self.ugrid.dump() } catch { self.log.error("Could not dump UGrid: \(error)") }
    #endif
  }

  // MARK: - Internal
  let queue = DispatchQueue(
    label: String(reflecting: NvimView.self),
    qos: .userInteractive
  )

  let bridge: UiBridge

  let ugrid = UGrid()
  let cellAttributesCollection = CellAttributesCollection()
  let drawer: AttributesRunDrawer
  var baselineOffset = 0.cgf

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

  var isCurrentlyPinching = false
  var pinchTargetScale = 1.cgf
  var pinchBitmap: NSBitmapImageRep?

  var currentlyResizing = false
  var currentEmoji = "😎"

  var _font = NvimView.defaultFont
  var _cwd = URL(fileURLWithPath: NSHomeDirectory())
  var isInitialResize = true

  // cache the tabs for Touch Bar use
  var tabsCache = [NvimView.Tabpage]()

  let eventsSubject = PublishSubject<Event>()
  let disposeBag = DisposeBag()

  var markedText: String?
  var markedPosition = Position.null

  let bridgeLogger = OSLog(subsystem: Defs.loggerSubsystem,
                           category: Defs.LoggerCategory.bridge)
  let log = OSLog(subsystem: Defs.loggerSubsystem,
                  category: Defs.LoggerCategory.view)

  let sourceFileUrls: [URL]

  let rpcEventSubscriptionCondition = ConditionVariable()
  let nvimExitedCondition = ConditionVariable()

  // MARK: - Private
  private var _linespacing = NvimView.defaultLinespacing
  private var _characterspacing = NvimView.defaultCharacterspacing
}
