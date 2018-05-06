/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxNeovimApi
import RxSwift

public class NvimView: NSView,
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

    case initVimError

    // FIXME: maybe do onError()?
    case apiError(msg: String, cause: Swift.Error)
  }

  public enum Error: Swift.Error {

    case nvimLaunch(msg: String, cause: Swift.Error)
    case ipc(msg: String, cause: Swift.Error)
  }

  public struct Theme: CustomStringConvertible {

    public static let `default` = Theme()

    public var foreground = NSColor.textColor
    public var background = NSColor.textBackgroundColor

    public var visualForeground = NSColor.selectedMenuItemTextColor
    public var visualBackground = NSColor.selectedMenuItemColor

    public var directoryForeground = NSColor.textColor

    public init() {
    }

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

  public static let minFontSize = CGFloat(4)
  public static let maxFontSize = CGFloat(128)
  public static let defaultFont = NSFont.userFixedPitchFont(ofSize: 12)!
  public static let defaultLinespacing = CGFloat(1)

  public static let minLinespacing = CGFloat(0.5)
  public static let maxLinespacing = CGFloat(8)

  public var isLeftOptionMeta = false
  public var isRightOptionMeta = false

  public let uuid = UUID().uuidString

  public internal(set) var mode = CursorModeShape.normal

  public internal(set) var theme = Theme.default

  public var trackpadScrollResistance = CGFloat(5)

  public var usesLiveResize = false

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
      self.api
        .setCurrentDir(dir: newValue.path, expectsReturnValue: false)
        .subscribeOn(self.scheduler)
        .subscribe(onError: { error in
          self.eventsSubject.onError(Error.ipc(msg: "Could not set cwd to \(newValue)", cause: error))
        })
    }
  }

  override public var acceptsFirstResponder: Bool {
    return true
  }

  public let queue = DispatchQueue(label: String(reflecting: NvimView.self), qos: .userInitiated)
  public let scheduler: SerialDispatchQueueScheduler

  public internal(set) var currentPosition = Position.beginning

  public var events: Observable<Event> {
    return self.eventsSubject.asObservable()
  }

  public init(frame rect: NSRect, config: Config) {
    self.drawer = TextDrawer(font: self._font)
    self.bridge = UiBridge(uuid: self.uuid, queue: self.queue, config: config)
    self.scheduler = SerialDispatchQueueScheduler(queue: self.queue,
                                                  internalSerialQueueName: "com.qvacua.NvimView.NvimView")

    super.init(frame: .zero)
    self.registerForDraggedTypes([NSPasteboard.PasteboardType(String(kUTTypeFileURL))])

    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    self.api.queue = self.queue
    self.bridge.stream
      .subscribe(onNext: { [unowned self] msg in
        switch msg {

        case .ready:
          self.logger.info("Nvim is ready")
          break

        case .initVimError:
          self.eventsSubject.onNext(.initVimError)

        case .unknown:
          break

        case let .resize(width, height):
          self.resize(width: width, height: height)

        case .clear:
          self.clear()

        case .setMenu:
          self.updateMenu()

        case .busyStart:
          self.busyStart()

        case .busyStop:
          self.busyStop()

        case .mouseOn:
          self.mouseOn()

        case .mouseOff:
          self.mouseOff()

        case let .modeChange(mode):
          self.modeChange(mode)

        case let .setScrollRegion(top, bottom, left, right):
          self.setScrollRegion(top: top, bottom: bottom, left: left, right: right)

        case let .scroll(amount):
          self.scroll(amount)

        case let .unmark(row, column):
          self.unmark(row: row, column: column)

        case .bell:
          self.bell()

        case .visualBell:
          self.visualBell()

        case let .flush(data):
          self.flush(data)

        case let .setForeground(value):
          self.update(foreground: value)

        case let .setBackground(value):
          self.update(background: value)

        case let .setSpecial(value):
          self.update(special: value)

        case let .setTitle(title):
          self.set(title: title)

        case let .setIcon(icon):
          self.set(icon: icon)

        case .stop:
          self.stop()

        case let .dirtyStatusChanged(value):
          self.set(dirty: value)

        case let .cwdChanged(path):
          self.cwdChanged(path)

        case let .colorSchemeChanged(values):
          self.colorSchemeChanged(values)

        case let .defaultColorsChanged(values):
          self.defaultColorsChanged(values)

        case let .optionSet(key, value):
          break

        case let .autoCommandEvent(autocmd, bufferHandle):
          self.autoCommandEvent(autocmd, bufferHandle: bufferHandle)

        case .debug1:
          self.debug1(self)

        }
      }, onError: { error in
        // FIXME
      })
      .disposed(by: self.disposeBag)
  }

  convenience override public init(frame rect: NSRect) {
    self.init(frame: rect, config: Config(useInteractiveZsh: false))
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction public func debug1(_ sender: Any?) {
    self.logger.debug("DEBUG 1 - Start")
    self.bridge
      .debug()
      .subscribe()
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
  let bridge: UiBridge
  let api = RxNeovimApi.Api()
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

  let eventsSubject = PublishSubject<Event>()
  let disposeBag = DisposeBag()

  // MARK: - Private
  private var _linespacing = NvimView.defaultLinespacing
}
