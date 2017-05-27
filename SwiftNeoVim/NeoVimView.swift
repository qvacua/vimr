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

    public init(useInteractiveZsh: Bool) {
      self.useInteractiveZsh = useInteractiveZsh
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
      return self.agent.pwd()
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

    self.launchNeoVim()
  }

  convenience override public init(frame rect: NSRect) {
    self.init(frame: rect, config: Config(useInteractiveZsh: false))
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction public func debug1(_ sender: Any?) {
    self.logger.debug("DEBUG 1 - Start")
    self.agent.cursorGo(toRow: 10, column: 5)
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

  static let emojis: [UInt32] = [
    0x1F600...0x1F64F,
    0x1F910...0x1F918,
    0x1F980...0x1F984,
    0x1F9C0...0x1F9C0
  ].flatMap { $0 }

  let logger = FileLogger(as: NeoVimView.self,
                          with: URL(fileURLWithPath: "/tmp/nvv.log"),
                          shouldLogDebug: false)
  let agent: NeoVimAgent
  let grid = Grid()

  let drawer: TextDrawer
  let fontManager = NSFontManager.shared()
  let pasteboard = NSPasteboard.general()

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

  let maxScrollDeltaX = 30
  let maxScrollDeltaY = 30
  let scrollLimiterX = CGFloat(20)
  let scrollLimiterY = CGFloat(20)
  var scrollGuardCounterX = 5
  var scrollGuardCounterY = 5
  let scrollGuardYield = 5

  var isCurrentlyPinching = false
  var pinchTargetScale = CGFloat(1)
  var pinchBitmap: NSBitmapImageRep?

  var currentlyResizing = false
  var currentEmoji = "😎"

  let colorSpace = NSColorSpace.sRGB

  var _font = NeoVimView.defaultFont

  // MARK: - Private
  fileprivate var _linespacing = NeoVimView.defaultLinespacing

  fileprivate func launchNeoVim() {
    self.logger.info("=== Starting neovim...")
    let noErrorDuringInitialization = self.agent.runLocalServerAndNeoVim()

    // Neovim is ready now: resize neovim to bounds.
    self.agent.vimCommand("set mouse=a")
    self.agent.setBoolOption("title", to: true)
    self.agent.setBoolOption("termguicolors", to: true)

    if noErrorDuringInitialization == false {
      self.logger.fault("There was an error launching neovim.")

      let alert = NSAlert()
      alert.alertStyle = .warning
      alert.messageText = "Error during initialization"
      alert.informativeText = "There was an error during the initialization of NeoVim. " +
                              "Use :messages to view the error messages."
      alert.runModal()
    }
  }
}
