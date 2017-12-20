/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack
import RxSwift

public class NvimView: NSView,
                       NvimUiBridgeProtocol,
                       NSUserInterfaceValidations,
                       NSTextInputClient {

  // MARK: - Public
  public struct Config {

    var useInteractiveZsh: Bool
    var cwd: URL
    var nvimArgs: [String]?

    public init(useInteractiveZsh: Bool,
                cwd: URL = URL(fileURLWithPath: NSHomeDirectory()),
                nvimArgs: [String]? = nil) {

      self.useInteractiveZsh = useInteractiveZsh
      self.cwd = cwd
      self.nvimArgs = nvimArgs
    }
  }

  public enum Event {

    case neoVimStopped
    case setTitle(String)
    case setDirtyStatus(Bool)
    case cwdChanged
    case bufferListChanged
    case tabChanged

    case newCurrentBuffer(NvimView.Buffer)
    case bufferWritten(NvimView.Buffer)

    case colorschemeChanged(NvimView.Theme)

    case ipcBecameInvalid(String)

    case scroll
    case cursor(Position)

    case initError
  }

  public struct Theme: CustomStringConvertible {

    public static let `default` = Theme()

    public var foreground = NSColor.textColor
    public var background = NSColor.textBackgroundColor

    public var visualForeground = NSColor.selectedMenuItemTextColor
    public var visualBackground = NSColor.selectedMenuItemColor

    public var directoryForeground = NSColor.textColor

    public init() {}

    public init(_ values: [Int]) {
      if values.count < 5 {
        preconditionFailure("We need 5 colors!")
      }

      let color = ColorUtils.colorIgnoringAlpha

      self.foreground = values[0] < 0 ? Theme.default.foreground : color(values[0])
      self.background = values[1] < 0 ? Theme.default.background : color(values[1])

      self.visualForeground = values[2] < 0 ? Theme.default.visualForeground : color(values[2])
      self.visualBackground = values[3] < 0 ? Theme.default.visualBackground : color(values[3])

      self.directoryForeground = values[4] < 0 ? Theme.default.directoryForeground : color(values[4])
    }

    public var description: String {
      return "NVV.Theme<" +
             "fg: \(self.foreground.hex), bg: \(self.background.hex), " +
             "visual-fg: \(self.visualForeground.hex), visual-bg: \(self.visualBackground.hex)" +
             ">"
    }
  }

  public enum Error: Swift.Error {

    case api(String)
  }

  public static let minFontSize = CGFloat(4)
  public static let maxFontSize = CGFloat(128)
  public static let defaultFont = NSFont.userFixedPitchFont(ofSize: 12)!
  public static let defaultLinespacing = CGFloat(1)

  public static let minLinespacing = CGFloat(0.5)
  public static let maxLinespacing = CGFloat(8)

  public let uuid = UUID().uuidString

  public internal(set) var mode = CursorModeShape.normal

  public internal(set) var theme = Theme.default

  public var usesLigatures = false {
    didSet {
      self.drawer.usesLigatures = self.usesLigatures
      self.needsDisplay = true
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
      self.drawer.linespacing = self.linespacing

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
      self.nvim.setCurrentDir(dir: newValue.path, expectsReturnValue: false)
    }
  }

  override public var acceptsFirstResponder: Bool {
    return true
  }

  public internal(set) var currentPosition = Position.beginning

  public var events: Observable<Event> {
    return self.eventsSubject.asObservable()
  }

  public init(frame rect: NSRect, config: Config) {
    self.drawer = TextDrawer(font: self._font)
    self.uiClient = UiClient(uuid: self.uuid)

    let sockPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vimr_\(self.uuid).sock").path
    guard let nvim = NvimApi(at: sockPath) else {
      preconditionFailure("Nvim could not be instantiated")
    }

    nvim.stream.scheduler = self.nvimApiScheduler
    self.nvim = nvim

    super.init(frame: .zero)
    self.registerForDraggedTypes([NSPasteboard.PasteboardType(String(kUTTypeFileURL))])

    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    // We cannot set bridge in init since self is not available before super.init()...
    self.uiClient.bridge = self
    self.uiClient.useInteractiveZsh = config.useInteractiveZsh
    self.uiClient.cwd = config.cwd
    self.uiClient.nvimArgs = config.nvimArgs
  }

  convenience override public init(frame rect: NSRect) {
    self.init(frame: rect, config: Config(useInteractiveZsh: false))
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction public func debug1(_ sender: Any?) {
    self.logger.debug("DEBUG 1 - Start")
    self.uiClient.debug()
    self.logger.debug("DEBUG 1 - End")
  }

  // MARK: - Internal
  /// Contiguous piece of cells of a row that has the same attributes.
  struct RowRun: CustomStringConvertible {

    var row: Int
    var range: CountableClosedRange<Int>
    var attrs: CellAttributes

    var description: String {
      return "RowRun<\(row): \(range)\n\(attrs)>"
    }
  }

  let logger = LogContext.fileLogger(as: NvimView.self, with: URL(fileURLWithPath: "/tmp/nvv.log"))
  let bridgeLogger = LogContext.fileLogger(as: NvimView.self,
                                           with: URL(fileURLWithPath: "/tmp/nvv-bridge.log"),
                                           shouldLogDebug: nil)
  let uiClient: UiClient
  let nvim: NvimApi
  let grid = Grid()

  let drawer: TextDrawer

  var markedText: String?

  /// We store the last marked text because Cocoa's text input system does the following:
  /// 하 -> hanja popup -> insertText(하) -> attributedSubstring...() -> setMarkedText(下) -> ...
  /// We want to return "하" in attributedSubstring...()
  var lastMarkedText: String?

  var markedPosition = Position.null
  var keyDownDone = true

  var lastClickedCellPosition = Position.null

  var xOffset = CGFloat(0)
  var yOffset = CGFloat(0)
  var cellSize = CGSize.zero
  var descent = CGFloat(0)
  var leading = CGFloat(0)

  var scrollGuardCounterX = 5
  var scrollGuardCounterY = 5

  var isCurrentlyPinching = false
  var pinchTargetScale = CGFloat(1)
  var pinchBitmap: NSBitmapImageRep?

  var currentlyResizing = false
  var currentEmoji = "😎"

  var _font = NvimView.defaultFont
  var _cwd = URL(fileURLWithPath: NSHomeDirectory())
  var shouldDrawCursor = false
  var isInitialResize = true

  // cache the tabs for Touch Bar use
  var tabsCache = [NvimView.Tabpage]()

  var nvimApiScheduler = SerialDispatchQueueScheduler(qos: .userInitiated)

  let eventsSubject = PublishSubject<Event>()

  // MARK: - Private
  private var _linespacing = NvimView.defaultLinespacing
}
