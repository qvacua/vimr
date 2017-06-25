/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public class NeoVimView: NSView,
                         NeoVimUiBridgeProtocol,
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

  public struct Theme: CustomStringConvertible {

    public static let `default` = Theme()

    public var foreground = NSColor.black
    public var background = NSColor.white
    public var visualForeground = NSColor.white
    public var visualBackground = NSColor.black

    public init() {}

    public init(_ values: [Int]) {
      self.foreground = ColorUtils.colorIgnoringAlpha(values[0])
      self.background = ColorUtils.colorIgnoringAlpha(values[1])
      self.visualForeground = ColorUtils.colorIgnoringAlpha(values[2])
      self.visualBackground = ColorUtils.colorIgnoringAlpha(values[3])
    }

    public var description: String {
      return "NVV.Theme<fg: \(self.foreground.hex), bg: \(self.background.hex), " +
             "v-fg: \(self.visualForeground.hex), v-bg: \(self.visualBackground.hex)>"
    }
  }

  public static let minFontSize = CGFloat(4)
  public static let maxFontSize = CGFloat(128)
  public static let defaultFont = NSFont.userFixedPitchFont(ofSize: 12)!
  public static let defaultLinespacing = CGFloat(1)

  public static let minLinespacing = CGFloat(0.5)
  public static let maxLinespacing = CGFloat(8)

  public let uuid = UUID().uuidString
  public weak var delegate: NeoVimViewDelegate?

  public internal(set) var mode = CursorModeShape.normal

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
      guard newValue >= NeoVimView.minLinespacing && newValue <= NeoVimView.maxLinespacing else {
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
      guard size >= NeoVimView.minFontSize && size <= NeoVimView.maxFontSize else {
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
      let path = newValue.path
      guard let escapedCwd = self.agent.escapedFileName(path) else {
        // this happens when VimR is quitting with some main windows open...
        self.logger.fault("Escaped file name returned nil.")
        return
      }

      self.agent.vimCommandOutput("cd \(escapedCwd)")
    }
  }

  override public var acceptsFirstResponder: Bool {
    return true
  }

  public internal(set) var currentPosition = Position.beginning

  public init(frame rect: NSRect, config: Config) {
    self.drawer = TextDrawer(font: self._font)
    self.agent = NeoVimAgent(uuid: self.uuid)

    super.init(frame: .zero)

    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    // We cannot set bridge in init since self is not available before super.init()...
    self.agent.bridge = self
    self.agent.useInteractiveZsh = config.useInteractiveZsh
    self.agent.cwd = config.cwd
    self.agent.nvimArgs = config.nvimArgs
  }

  convenience override public init(frame rect: NSRect) {
    self.init(frame: rect, config: Config(useInteractiveZsh: false))
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction public func debug1(_ sender: Any?) {
    self.logger.debug("DEBUG 1 - Start")
    self.agent.debug()
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

  let logger = FileLogger(as: NeoVimView.self, with: URL(fileURLWithPath: "/tmp/nvv.log"))
  let bridgeLogger = FileLogger(as: NeoVimView.self,
                                with: URL(fileURLWithPath: "/tmp/nvv-bridge.log"),
                                shouldLogDebug: nil)
  let agent: NeoVimAgent
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

  var _font = NeoVimView.defaultFont
  var _cwd = URL(fileURLWithPath: NSHomeDirectory())
  var shouldDrawCursor = false
  let quitNeoVimCondition = NSCondition()
  var isNeoVimQuitSuccessful = false
  var isInitialResize = true

  // MARK: - Private
  fileprivate var _linespacing = NeoVimView.defaultLinespacing
}
