/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

/// Contiguous piece of cells of a row that has the same attributes.
fileprivate struct RowRun: CustomStringConvertible {

  var row: Int
  var range: CountableClosedRange<Int>
  var attrs: CellAttributes

  var description: String {
    return "RowRun<\(row): \(range)\n\(attrs)>"
  }
}

public class NeoVimView: NSView, NeoVimUiBridgeProtocol, NSUserInterfaceValidations {

  public struct Config {

    var useInteractiveZsh: Bool

    public init(useInteractiveZsh: Bool) {
      self.useInteractiveZsh = useInteractiveZsh
    }
  }

  public static let minFontSize = CGFloat(4)
  public static let maxFontSize = CGFloat(128)
  public static let defaultFont = NSFont.userFixedPitchFont(ofSize: 13)!
  public static let defaultLinespacing = CGFloat(1)

  public static let minLinespacing = CGFloat(0.5)
  public static let maxLinespacing = CGFloat(8)

  public let uuid = UUID().uuidString
  public weak var delegate: NeoVimViewDelegate?

  public fileprivate(set) var mode = CursorModeShape.normal

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
        NSLog("WARN \(#function): escaped file name returned nil")
        return
      }

      self.agent.vimCommandOutput("cd \(escapedCwd)")
    }
  }

  override public var acceptsFirstResponder: Bool {
    return true
  }

  public fileprivate(set) var currentPosition = Position.beginning

  fileprivate static let emojis: [UInt32] = [
    0x1F600...0x1F64F,
    0x1F910...0x1F918,
    0x1F980...0x1F984,
    0x1F9C0...0x1F9C0
  ].flatMap { $0 }

  fileprivate var _font = NeoVimView.defaultFont
  fileprivate var _linespacing = NeoVimView.defaultLinespacing

  fileprivate let agent: NeoVimAgent
  fileprivate let drawer: TextDrawer
  fileprivate let fontManager = NSFontManager.shared()
  fileprivate let pasteboard = NSPasteboard.general()

  fileprivate let grid = Grid()

  fileprivate var markedText: String?

  /// We store the last marked text because Cocoa's text input system does the following:
  /// 하 -> hanja popup -> insertText(하) -> attributedSubstring...() -> setMarkedText(下) -> ...
  /// We want to return "하" in attributedSubstring...()
  fileprivate var lastMarkedText: String?

  fileprivate var markedPosition = Position.null
  fileprivate var keyDownDone = true

  fileprivate var lastClickedCellPosition = Position.null

  fileprivate var xOffset = CGFloat(0)
  fileprivate var yOffset = CGFloat(0)
  fileprivate var cellSize = CGSize.zero
  fileprivate var descent = CGFloat(0)
  fileprivate var leading = CGFloat(0)

  fileprivate let maxScrollDeltaX = 30
  fileprivate let maxScrollDeltaY = 30
  fileprivate let scrollLimiterX = CGFloat(20)
  fileprivate let scrollLimiterY = CGFloat(20)
  fileprivate var scrollGuardCounterX = 5
  fileprivate var scrollGuardCounterY = 5
  fileprivate let scrollGuardYield = 5

  fileprivate var isCurrentlyPinching = false
  fileprivate var pinchTargetScale = CGFloat(1)
  fileprivate var pinchBitmap: NSBitmapImageRep?

  fileprivate var currentlyResizing = false
  fileprivate var currentEmoji = "😎"
  fileprivate let emojiAttrs = [
    NSFontAttributeName: NSFont(name: "AppleColorEmoji", size: 72)!
  ]
  fileprivate let resizeTextAttrs = [
    NSFontAttributeName: NSFont.systemFont(ofSize: 18),
    NSForegroundColorAttributeName: NSColor.darkGray
  ]

  fileprivate let colorSpace = NSColorSpace.sRGB

  public init(frame rect: NSRect, config: Config) {
    self.drawer = TextDrawer(font: self._font)
    self.agent = NeoVimAgent(uuid: self.uuid)

    super.init(frame: CGRect.zero)

    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    // We cannot set bridge in init since self is not available before super.init()...
    self.agent.bridge = self
    self.agent.useInteractiveZsh = config.useInteractiveZsh
    let noErrorDuringInitialization = self.agent.runLocalServerAndNeoVim()

    // Neovim is ready now: resize neovim to bounds.
    DispatchQueue.main.async {
      self.agent.setBoolOption("title", to: true)
      self.agent.setBoolOption("termguicolors", to: true)

      if noErrorDuringInitialization == false {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Error during initialization"
        alert.informativeText = "There was an error during the initialization of NeoVim. "
                                + "Use :messages to view the error messages."
        alert.runModal()
      }

      self.resizeNeoVimUiTo(size: self.bounds.size)
    }
  }

  override public func viewDidMoveToWindow() {
    self.window?.colorSpace = self.colorSpace
  }

  convenience override init(frame rect: NSRect) {
    self.init(frame: rect, config: Config(useInteractiveZsh: false))
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction public func debug1(_ sender: AnyObject?) {
    NSLog("DEBUG 1 - Start")
    self.agent.cursorGo(toRow: 10, column: 5)
    NSLog("DEBUG 1 - End")
  }

  fileprivate func updateFontMetaData(_ newFont: NSFont) {
    self.drawer.font = newFont

    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    self.resizeNeoVimUiTo(size: self.bounds.size)
  }
}

// MARK: - API
extension NeoVimView {

  public func enterResizeMode() {
    self.currentlyResizing = true
    self.needsDisplay = true
  }

  public func exitResizeMode() {
    self.currentlyResizing = false
    self.needsDisplay = true
    self.resizeNeoVimUiTo(size: self.bounds.size)
  }

  /**
   - returns: nil when for exampls a quickfix panel is open.
   */
  public func currentBuffer() -> NeoVimBuffer? {
    return self.agent.buffers().first { $0.isCurrent }
  }

  public func allBuffers() -> [NeoVimBuffer] {
    return self.agent.tabs().map { $0.allBuffers() }.flatMap { $0 }
  }

  public func hasDirtyDocs() -> Bool {
    return self.agent.hasDirtyDocs()
  }

  public func isCurrentBufferDirty() -> Bool {
    let curBuf = self.currentBuffer()
    return curBuf?.isDirty ?? true
  }

  public func newTab() {
    self.exec(command: "tabe")
  }

  public func open(urls: [URL]) {
    let tabs = self.agent.tabs()
    let buffers = self.allBuffers()
    let currentBufferIsTransient = buffers.first { $0.isCurrent }?.isTransient ?? false

    urls.enumerated().forEach { (idx, url) in
      if buffers.filter({ $0.url == url }).first != nil {
        for window in tabs.map({ $0.windows }).flatMap({ $0 }) {
          if window.buffer.url == url {
            self.agent.select(window)
            return
          }
        }
      }

      if currentBufferIsTransient {
        self.open(url, cmd: "e")
      } else {
        self.open(url, cmd: "tabe")
      }
    }
  }

  public func openInNewTab(urls: [URL]) {
    urls.forEach { self.open($0, cmd: "tabe") }
  }

  public func openInCurrentTab(url: URL) {
    self.open(url, cmd: "e")
  }

  public func openInHorizontalSplit(urls: [URL]) {
    urls.forEach { self.open($0, cmd: "sp") }
  }

  public func openInVerticalSplit(urls: [URL]) {
    urls.forEach { self.open($0, cmd: "vsp") }
  }

  public func select(buffer: NeoVimBuffer) {
    for window in self.agent.tabs().map({ $0.windows }).flatMap({ $0 }) {
      if window.buffer.handle == buffer.handle {
        self.agent.select(window)
        return
      }
    }
  }

  public func closeCurrentTab() {
    self.exec(command: "q")
  }

  public func saveCurrentTab() {
    self.exec(command: "w")
  }

  public func saveCurrentTab(url: URL) {
    let path = url.path
    guard let escapedFileName = self.agent.escapedFileName(path) else {
      NSLog("WARN \(#function): escaped file name returned nil")
      return
    }

    self.exec(command: "w \(escapedFileName)")
  }

  public func closeCurrentTabWithoutSaving() {
    self.exec(command: "q!")
  }

  public func closeAllWindows() {
    self.exec(command: "qa")
  }

  public func closeAllWindowsWithoutSaving() {
    self.exec(command: "qa!")
  }

  public func vimOutput(of command: String) -> String {
    return self.agent.vimCommandOutput(command) ?? ""
  }

  public func cursorGo(to position: Position) {
    self.agent.cursorGo(toRow: Int32(position.row), column: Int32(position.column))
  }

  /**
   Does the following
   - normal mode: `:command<CR>`
   - else: `:<Esc>:command<CR>`

   We don't use NeoVimAgent.vimCommand because if we do for example "e /some/file" and its swap file already exists,
   then NeoVimServer spins and become unresponsive.
  */
  fileprivate func exec(command cmd: String) {
    switch self.mode {
    case .normal:
      self.agent.vimInput(":\(cmd)<CR>")
    default:
      self.agent.vimInput("<Esc>:\(cmd)<CR>")
    }
  }

  fileprivate func open(_ url: URL, cmd: String) {
    let path = url.path
    guard let escapedFileName = self.agent.escapedFileName(path) else {
      NSLog("WARN \(#function): escaped file name returned nil")
      return
    }

    self.exec(command: "\(cmd) \(escapedFileName)")
  }
}

// MARK: - Resizing
extension NeoVimView {

  override public func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)

    // initial resizing is done when grid has data
    guard self.grid.hasData else {
      return
    }

    if self.inLiveResize || self.currentlyResizing {
      // TODO: Turn off live resizing for now.
      // self.resizeNeoVimUiTo(size: newSize)
      return
    }

    // There can be cases where the frame is resized not by live resizing, eg when the window is resized by window
    // management tools. Thus, we make sure that the resize call is made when this happens.
    self.resizeNeoVimUiTo(size: newSize)
  }

  override public func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    self.resizeNeoVimUiTo(size: self.bounds.size)
  }

  fileprivate func resizeNeoVimUiTo(size: CGSize) {
    self.currentEmoji = self.randomEmoji()

//    NSLog("\(#function): \(size)")
    let discreteSize = self.discreteSize(size: size)

    if discreteSize == self.grid.size {
      return
    }

    self.xOffset = floor((size.width - self.cellSize.width * CGFloat(discreteSize.width)) / 2)
    self.yOffset = floor((size.height - self.cellSize.height * CGFloat(discreteSize.height)) / 2)

    self.agent.resize(toWidth: Int32(discreteSize.width), height: Int32(discreteSize.height))
  }

  fileprivate func discreteSize(size: CGSize) -> Size {
    return Size(width: Int(floor(size.width / self.cellSize.width)),
                height: Int(floor(size.height / self.cellSize.height)))
  }
}

// MARK: - Drawing
extension NeoVimView {

  override public func draw(_ dirtyUnionRect: NSRect) {
    guard self.grid.hasData else {
      return
    }

    if self.inLiveResize || self.currentlyResizing {
      NSColor.windowBackgroundColor.set()
      dirtyUnionRect.fill()

      let boundsSize = self.bounds.size

      let emojiSize = self.currentEmoji.size(withAttributes: self.emojiAttrs)
      let emojiX = (boundsSize.width - emojiSize.width) / 2
      let emojiY = (boundsSize.height - emojiSize.height) / 2

      let discreteSize = self.discreteSize(size: boundsSize)
      let displayStr = "\(discreteSize.width) × \(discreteSize.height)"

      let size = displayStr.size(withAttributes: self.resizeTextAttrs)
      let x = (boundsSize.width - size.width) / 2
      let y = emojiY - size.height

      self.currentEmoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: self.emojiAttrs)
      displayStr.draw(at: CGPoint(x: x, y: y), withAttributes: self.resizeTextAttrs)

      return
    }

//    NSLog("\(#function): \(dirtyUnionRect)")
    let context = NSGraphicsContext.current()!.cgContext

    if self.isCurrentlyPinching {
      let interpolationQuality = context.interpolationQuality
      context.interpolationQuality = .none

      let boundsSize = self.bounds.size
      let targetSize = CGSize(width: boundsSize.width * self.pinchTargetScale,
                              height: boundsSize.height * self.pinchTargetScale)
      self.pinchBitmap?.draw(in: CGRect(origin: self.bounds.origin, size: targetSize),
                             from: CGRect.zero,
                             operation: .sourceOver,
                             fraction: 1,
                             respectFlipped: true,
                             hints: nil)

      context.interpolationQuality = interpolationQuality

      return
    }

    // When both anti-aliasing and font smoothing is turned on, then the "Use LCD font smoothing when available" setting
    // is used to render texts, cf. chapter 11 from "Programming with Quartz".
    context.setShouldSmoothFonts(true);
    context.textMatrix = CGAffineTransform.identity;
    context.setTextDrawingMode(.fill);

    let dirtyRects = self.rectsBeingDrawn()
//    NSLog("\(dirtyRects)")

    self.rowRunIntersecting(rects: dirtyRects).forEach { self.draw(rowRun: $0, context: context) }
    self.drawCursor(context: context)
  }

  fileprivate func randomEmoji() -> String {
    let idx = Int(arc4random_uniform(UInt32(NeoVimView.emojis.count)))
    guard let scalar = UnicodeScalar(NeoVimView.emojis[idx]) else {
      return "😎"
    }

    return String(scalar)
  }

  fileprivate func draw(rowRun rowFrag: RowRun, context: CGContext) {
    // For background drawing we don't filter out the put(0, 0)s: in some cases only the put(0, 0)-cells should be
    // redrawn. => FIXME: probably we have to consider this also when drawing further down, ie when the range starts
    // with '0'...
    self.drawBackground(positions: rowFrag.range.map { self.pointInViewFor(row: rowFrag.row, column: $0) },
                        background: rowFrag.attrs.background)

    let positions = rowFrag.range
      // filter out the put(0, 0)s (after a wide character)
      .filter { self.grid.cells[rowFrag.row][$0].string.characters.count > 0 }
      .map { self.pointInViewFor(row: rowFrag.row, column: $0) }

    if positions.isEmpty {
      return
    }

    let string = self.grid.cells[rowFrag.row][rowFrag.range].reduce("") { $0 + $1.string }
    let offset = self.drawer.baselineOffset
    let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + offset) }

    self.drawer.draw(string,
                     positions: UnsafeMutablePointer(mutating: glyphPositions), positionsCount: positions.count,
                     highlightAttrs: rowFrag.attrs,
                     context: context)
  }

  fileprivate func cursorRegion() -> Region {
    let cursorPosition = self.mode == .cmdline ? self.grid.putPosition : self.grid.screenCursor
//    NSLog("\(#function): \(cursorPosition)")

    let saneRow = max(0, min(cursorPosition.row, self.grid.size.height - 1))
    let saneColumn = max(0, min(cursorPosition.column, self.grid.size.width - 1))

    var cursorRegion = Region(top: saneRow, bottom: saneRow, left: saneColumn, right: saneColumn)

    if self.grid.isNextCellEmpty(cursorPosition) {
      cursorRegion = Region(top: cursorPosition.row,
                            bottom: cursorPosition.row,
                            left: cursorPosition.column,
                            right: min(self.grid.size.width - 1, cursorPosition.column + 1))
    }

    return cursorRegion
  }

  fileprivate func drawCursor(context: CGContext) {
    let cursorRegion = self.cursorRegion()
    let cursorRow = cursorRegion.top
    let cursorColumnStart = cursorRegion.left

    if self.mode == .insert {
      ColorUtils.colorIgnoringAlpha(self.grid.foreground).withAlphaComponent(0.75).set()
      var cursorRect = self.cellRectFor(row: cursorRow, column: cursorColumnStart)
      cursorRect.size.width = 2
      cursorRect.fill()
      return
    }

    // FIXME: for now do some rudimentary cursor drawing
    let attrsAtCursor = self.grid.cells[cursorRow][cursorColumnStart].attrs
    let attrs = CellAttributes(fontTrait: attrsAtCursor.fontTrait,
                               foreground: self.grid.background,
                               background: self.grid.foreground,
                               special: self.grid.special)

    // FIXME: take ligatures into account (is it a good idea to do this?)
    let rowRun = RowRun(row: cursorRegion.top, range: cursorRegion.columnRange, attrs: attrs)
    self.draw(rowRun: rowRun, context: context)
  }

  fileprivate func drawBackground(positions: [CGPoint], background: UInt32) {
    ColorUtils.colorIgnoringAlpha(background).set()
//    NSColor(calibratedRed: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0).set()
    let backgroundRect = CGRect(
      x: positions[0].x, y: positions[0].y,
      width: CGFloat(positions.count) * self.cellSize.width, height: self.cellSize.height
    )
    backgroundRect.fill()
  }

  fileprivate func rowRunIntersecting(rects: [CGRect]) -> [RowRun] {
    return rects
      .map { rect -> (CountableClosedRange<Int>, CountableClosedRange<Int>) in
        // Get all Regions that intersects with the given rects. There can be overlaps between the Regions, but for the
        // time being we ignore them; probably not necessary to optimize them away.
        let region = self.regionFor(rect: rect)
        return (region.rowRange, region.columnRange)
      }
      .map { self.rowRunsFor(rowRange: $0, columnRange: $1) } // All RowRuns for all Regions grouped by their row range.
      .flatMap { $0 }                                         // Flattened RowRuns for all Regions.
  }

  fileprivate func rowRunsFor(rowRange: CountableClosedRange<Int>, columnRange: CountableClosedRange<Int>) -> [RowRun] {
    return rowRange
      .map { (row) -> [RowRun] in
        let rowCells = self.grid.cells[row]
        let startIdx = columnRange.lowerBound

        var result = [RowRun(row: row, range: startIdx...startIdx, attrs: rowCells[startIdx].attrs)]
        columnRange.forEach { idx in
          if rowCells[idx].attrs == result.last!.attrs {
            let last = result.popLast()!
            result.append(RowRun(row: row, range: last.range.lowerBound...idx, attrs: last.attrs))
          } else {
            result.append(RowRun(row: row, range: idx...idx, attrs: rowCells[idx].attrs))
          }
        }

        return result // All RowRuns for a row in a Region.
      }               // All RowRuns for all rows in a Region grouped by row.
      .flatMap { $0 } // Flattened RowRuns for a Region.
  }

  fileprivate func regionFor(rect: CGRect) -> Region {
    let cellWidth = self.cellSize.width
    let cellHeight = self.cellSize.height

    let rowStart = max(
      Int(floor((self.bounds.height - self.yOffset - (rect.origin.y + rect.size.height)) / cellHeight)), 0
    )
    let rowEnd = min(
      Int(ceil((self.bounds.height - self.yOffset - rect.origin.y) / cellHeight)) - 1, self.grid.size.height - 1
    )
    let columnStart = max(
      Int(floor((rect.origin.x - self.xOffset) / cellWidth)), 0
    )
    let columnEnd = min(
      Int(ceil((rect.origin.x - self.xOffset + rect.size.width) / cellWidth)) - 1, self.grid.size.width - 1
    )

    return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
  }

  fileprivate func pointInViewFor(position: Position) -> CGPoint {
    return self.pointInViewFor(row: position.row, column: position.column)
  }

  fileprivate func pointInViewFor(row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: self.xOffset + CGFloat(column) * self.cellSize.width,
      y: self.bounds.size.height - self.yOffset - CGFloat(row) * self.cellSize.height - self.cellSize.height
    )
  }

  fileprivate func cellRectFor(row: Int, column: Int) -> CGRect {
    return CGRect(origin: self.pointInViewFor(row: row, column: column), size: self.cellSize)
  }

  fileprivate func regionRectFor(region: Region) -> CGRect {
    let top = CGFloat(region.top)
    let bottom = CGFloat(region.bottom)
    let left = CGFloat(region.left)
    let right = CGFloat(region.right)

    let width = right - left + 1
    let height = bottom - top + 1

    let cellWidth = self.cellSize.width
    let cellHeight = self.cellSize.height

    return CGRect(
      x: self.xOffset + left * cellWidth,
      y: self.bounds.size.height - self.yOffset - top * cellHeight - height * cellHeight,
      width: width * cellWidth,
      height: height * cellHeight
    )
  }

  fileprivate func wrapNamedKeys(_ string: String) -> String {
    return "<\(string)>"
  }

  fileprivate func vimPlainString(_ string: String) -> String {
    return string.replacingOccurrences(of: "<", with: self.wrapNamedKeys("lt"))
  }
}

// MARK: - NSUserInterfaceValidationsProtocol
extension NeoVimView {

  public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let canUndoOrRedo = self.mode == .insert || self.mode == .replace || self.mode == .normal || self.mode == .visual
    let canCopyOrCut = self.mode == .normal || self.mode == .visual
    let canPaste = self.pasteboard.string(forType: NSPasteboardTypeString) != nil
    let canDelete = self.mode == .visual || self.mode == .normal
    let canSelectAll = self.mode == .insert || self.mode == .replace || self.mode == .normal || self.mode == .visual

    guard let action = item.action else {
      return true
    }

    switch action {
    case #selector(undo(_:)), #selector(redo(_:)):
      return canUndoOrRedo
    case #selector(copy(_:)), #selector(cut(_:)):
      return canCopyOrCut
    case #selector(paste(_:)):
      return canPaste
    case #selector(delete(_:)):
      return canDelete
    case #selector(selectAll(_:)):
      return canSelectAll
    default:
      return true
    }
  }
}

// MARK: - Edit Menu Items
extension NeoVimView {

  @IBAction func undo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.agent.vimInput("<Esc>ui")
    case .normal, .visual:
      self.agent.vimInput("u")
    default:
      return
    }
  }

  @IBAction func redo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.agent.vimInput("<Esc><C-r>i")
    case .normal, .visual:
      self.agent.vimInput("<C-r>")
    default:
      return
    }
  }

  @IBAction func cut(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.agent.vimInput("\"+d")
    default:
      return
    }
  }

  @IBAction func copy(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.agent.vimInput("\"+y")
    default:
      return
    }
  }

  @IBAction func paste(_ sender: AnyObject?) {
    guard let content = self.pasteboard.string(forType: NSPasteboardTypeString) else {
      return
    }

    if self.mode == .cmdline || self.mode == .replace || self.mode == .termFocus {
      self.agent.vimInput(self.vimPlainString(content))
      return
    }

    guard let curPasteMode = self.agent.boolOption("paste") else {
      self.ipcBecameInvalid("Reason: 'set paste' failed")
      return
    }

    let pasteModeSet: Bool

    if curPasteMode == false {
      self.agent.setBoolOption("paste", to: true)
      pasteModeSet = true
    } else {
      pasteModeSet = false
    }

    let resetPasteModeCmd = pasteModeSet ? ":set nopaste<CR>" : ""

    switch self.mode {
    case .insert:
      self.agent.vimInput("<ESC>\"+p\(resetPasteModeCmd)a")
    case .normal, .visual:
      self.agent.vimInput("\"+p\(resetPasteModeCmd)")
    default:
      return
    }
  }

  @IBAction func delete(_ sender: AnyObject?) {
    switch self.mode {
    case .normal, .visual:
      self.agent.vimInput("x")
    default:
      return
    }
  }

  @IBAction public override func selectAll(_ sender: Any?) {
    switch self.mode {
    case .insert, .visual:
      self.agent.vimInput("<Esc>ggVG")
    default:
      self.agent.vimInput("ggVG")
    }
  }
}

// MARK: - Font Menu Items
extension NeoVimView {

  @IBAction func resetFontSize(_ sender: Any?) {
    self.font = self._font
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.drawer.font
    let font = self.fontManager.convert(curFont, toSize: min(curFont.pointSize + 1, NeoVimView.maxFontSize))
    self.updateFontMetaData(font)
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.drawer.font
    let font = self.fontManager.convert(curFont, toSize: max(curFont.pointSize - 1, NeoVimView.minFontSize))
    self.updateFontMetaData(font)
  }
}

// MARK: - Key Events
extension NeoVimView: NSTextInputClient {

  override public func keyDown(with event: NSEvent) {
    self.keyDownDone = false

    let context = NSTextInputContext.current()!
    let cocoaHandledEvent = context.handleEvent(event)
    if self.keyDownDone && cocoaHandledEvent {
      return
    }

//    NSLog("\(#function): \(event)")

    let modifierFlags = event.modifierFlags
    let capslock = modifierFlags.contains(.capsLock)
    let shift = modifierFlags.contains(.shift)
    let chars = event.characters!
    let charsIgnoringModifiers = shift || capslock
      ? event.charactersIgnoringModifiers!.lowercased()
      : event.charactersIgnoringModifiers!

    if KeyUtils.isSpecial(key: charsIgnoringModifiers) {
      if let vimModifiers = self.vimModifierFlags(modifierFlags) {
        self.agent.vimInput(self.wrapNamedKeys(vimModifiers + KeyUtils.namedKeyFrom(key: charsIgnoringModifiers)))
      } else {
        self.agent.vimInput(self.wrapNamedKeys(KeyUtils.namedKeyFrom(key: charsIgnoringModifiers)))
      }
    } else {
      if let vimModifiers = self.vimModifierFlags(modifierFlags) {
        self.agent.vimInput(self.wrapNamedKeys(vimModifiers + charsIgnoringModifiers))
      } else {
        self.agent.vimInput(self.vimPlainString(chars))
      }
    }

    self.keyDownDone = true
  }

  public func insertText(_ aString: Any, replacementRange: NSRange) {
//    NSLog("\(#function): \(replacementRange): '\(aString)'")

    switch aString {
    case let string as String:
      self.agent.vimInput(self.vimPlainString(string))
    case let attributedString as NSAttributedString:
      self.agent.vimInput(self.vimPlainString(attributedString.string))
    default:
      break;
    }

    // unmarkText()
    self.lastMarkedText = self.markedText
    self.markedText = nil
    self.markedPosition = Position.null
    self.keyDownDone = true
  }

  public override func doCommand(by aSelector: Selector) {
//    NSLog("\(#function): \(aSelector)");

    // FIXME: handle when ㅎ -> delete

    if self.responds(to: aSelector) {
      Swift.print("\(#function): calling \(aSelector)")
      self.perform(aSelector, with: self)
      self.keyDownDone = true
      return
    }

//    NSLog("\(#function): "\(aSelector) not implemented, forwarding input to vim")
    self.keyDownDone = false
  }

  public func setMarkedText(_ aString: Any, selectedRange: NSRange, replacementRange: NSRange) {
    if self.markedText == nil {
      self.markedPosition = self.grid.putPosition
    }

    // eg 하 -> hanja popup, cf comment for self.lastMarkedText
    if replacementRange.length > 0 {
      self.agent.deleteCharacters(replacementRange.length)
    }

    switch aString {
    case let string as String:
      self.markedText = string
    case let attributedString as NSAttributedString:
      self.markedText = attributedString.string
    default:
      self.markedText = String(describing: aString) // should not occur
    }

//    NSLog("\(#function): \(self.markedText), \(selectedRange), \(replacementRange)")

    self.agent.vimInputMarkedText(self.markedText!)
    self.keyDownDone = true
  }

  public func unmarkText() {
//    NSLog("\(#function): ")
    self.markedText = nil
    self.markedPosition = Position.null
    self.keyDownDone = true

    // TODO: necessary?
    self.markForRender(row: self.grid.putPosition.row, column: self.grid.putPosition.column)
  }

  /// Return the current selection (or the position of the cursor with empty-length range). For example when you enter
  /// "Cmd-Ctrl-Return" you'll get the Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where the
  /// first range is the result of this method.
  public func selectedRange() -> NSRange {
    // When the app starts and the Hangul input method is selected, this method gets called very early...
    guard self.grid.hasData else {
//      NSLog("\(#function): not found")
      return NSRange(location: NSNotFound, length: 0)
    }

    let result = NSRange(location: self.grid.singleIndexFrom(self.grid.putPosition), length: 0)
//    NSLog("\(#function): \(result)")
    return result
  }

  public func markedRange() -> NSRange {
    // FIXME: do we have to handle positions at the column borders?
    if let markedText = self.markedText {
      let result = NSRange(location: self.grid.singleIndexFrom(self.markedPosition),
                           length: markedText.characters.count)
//      NSLog("\(#function): \(result)")
      return result
    }

    NSLog("\(#function): returning empty range")
    return NSRange(location: NSNotFound, length: 0)
  }

  public func hasMarkedText() -> Bool {
//    NSLog("\(#function)")
    return self.markedText != nil
  }

  // FIXME: take into account the "return nil"-case
  // FIXME: just fix me, PLEASE...
  public func attributedSubstring(forProposedRange aRange: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
//    NSLog("\(#function): \(aRange), \(actualRange[0])")
    if aRange.location == NSNotFound {
//      NSLog("\(#function): range not found: returning nil")
      return nil
    }

    guard let lastMarkedText = self.lastMarkedText else {
//      NSLog("\(#function): no last marked text: returning nil")
      return nil
    }

    // we only support last marked text, thus fill dummy characters when Cocoa asks for more characters than marked...
    let fillCount = aRange.length - lastMarkedText.characters.count
    guard fillCount >= 0 else {
      return nil
    }

    let fillChars = Array(0..<fillCount).reduce("") { (result, _) in return result + " " }

//    NSLog("\(#function): \(aRange), \(actualRange[0]): \(fillChars + lastMarkedText)")
    return NSAttributedString(string: fillChars + lastMarkedText)
  }

  public func validAttributesForMarkedText() -> [String] {
    return []
  }

  public func firstRect(forCharacterRange aRange: NSRange, actualRange: NSRangePointer?) -> NSRect {
    let position = self.grid.positionFromSingleIndex(aRange.location)

//    NSLog("\(#function): \(aRange),\(actualRange[0]) -> \(position.row):\(position.column)")

    let resultInSelf = self.cellRectFor(row: position.row, column: position.column)
    let result = self.window?.convertToScreen(self.convert(resultInSelf, to: nil))

    return result!
  }

  public func characterIndex(for aPoint: NSPoint) -> Int {
//    NSLog("\(#function): \(aPoint)")
    return 1
  }

  fileprivate func vimModifierFlags(_ modifierFlags: NSEventModifierFlags) -> String? {
    var result = ""

    let control = modifierFlags.contains(.control)
    let option = modifierFlags.contains(.option)
    let command = modifierFlags.contains(.command)

    if control {
      result += "C-"
    }

    if option {
      result += "M-"
    }

    if command {
      result += "D-"
    }

    if result.characters.count > 0 {
      return result
    }

    return nil
  }
}

// MARK: - Gesture Events
extension NeoVimView {

  override public func magnify(with event: NSEvent) {
    let factor = 1 + event.magnification
    let pinchTargetScale = self.pinchTargetScale * factor
    let resultingFontSize = round(pinchTargetScale * self._font.pointSize)
    if resultingFontSize >= NeoVimView.minFontSize && resultingFontSize <= NeoVimView.maxFontSize {
      self.pinchTargetScale = pinchTargetScale
    }

    switch event.phase {
    case NSEventPhase.began:
      let pinchImageRep = self.bitmapImageRepForCachingDisplay(in: self.bounds)!
      self.cacheDisplay(in: self.bounds, to: pinchImageRep)
      self.pinchBitmap = pinchImageRep

      self.isCurrentlyPinching = true
      self.needsDisplay = true

    case NSEventPhase.ended, NSEventPhase.cancelled:
      self.isCurrentlyPinching = false
      self.updateFontMetaData(self.fontManager.convert(self._font, toSize: resultingFontSize))
      self.pinchTargetScale = 1

    default:
      self.needsDisplay = true
    }
  }
}

// MARK: - Mouse Events
extension NeoVimView {

  override public func mouseDown(with event: NSEvent) {
//    self.window?.makeFirstResponder(self)
    self.mouse(event: event, vimName: "LeftMouse")
  }

  override public func mouseUp(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftRelease")
  }

  override public func mouseDragged(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftDrag")
  }

  override public func scrollWheel(with event: NSEvent) {
    let (deltaX, deltaY) = (event.scrollingDeltaX, event.scrollingDeltaY)
    if deltaX == 0 && deltaY == 0 {
      return
    }

    let isTrackpad = event.hasPreciseScrollingDeltas

    let cellPosition = self.cellPositionFor(event: event)
    let (vimInputX, vimInputY) = self.vimScrollInputFor(deltaX: deltaX, deltaY: deltaY,
                                                        modifierFlags: event.modifierFlags,
                                                        cellPosition: cellPosition)

    // We patched neovim such that it scrolls only 1 line for each scroll input. The default is 3 and for mouse
    // scrolling we restore the original behavior.
    if isTrackpad == false {
      (0..<3).forEach { _ in
        self.agent.vimInput(vimInputX)
        self.agent.vimInput(vimInputY)
      }

      return
    }

    let (absDeltaX, absDeltaY) = (abs(deltaX), abs(deltaY))

    // The absolute delta values can get very very big when you use two finger scrolling on the trackpad:
    // Cap them using heuristic values...
    let numX = deltaX != 0 ? max(1, min(Int(absDeltaX / self.scrollLimiterX), self.maxScrollDeltaX)) : 0
    let numY = deltaY != 0 ? max(1, min(Int(absDeltaY / self.scrollLimiterY), self.maxScrollDeltaY)) : 0

    for i in 0..<max(numX, numY) {
      if i < numX {
        self.throttleScrollX(absDelta: absDeltaX, vimInput: vimInputX)
      }

      if i < numY {
        self.throttleScrollY(absDelta: absDeltaY, vimInput: vimInputY)
      }
    }
  }

  fileprivate func cellPositionFor(event: NSEvent) -> Position {
    let location = self.convert(event.locationInWindow, from: nil)
    let row = Int((location.x - self.xOffset) / self.cellSize.width)
    let column = Int((self.bounds.size.height - location.y - self.yOffset) / self.cellSize.height)

    let cellPosition = Position(row: min(max(0, row), self.grid.size.width - 1),
                                column: min(max(0, column), self.grid.size.height - 1))
    return cellPosition
  }

  fileprivate func mouse(event: NSEvent, vimName: String) {
    let cellPosition = self.cellPositionFor(event: event)
    guard self.shouldFireVimInputFor(event: event, newCellPosition: cellPosition) else {
      return
    }

    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.row),\(cellPosition.column)")
    let vimClickCount = self.vimClickCountFrom(event: event)

    let result: String
    if let vimModifiers = self.vimModifierFlags(event.modifierFlags) {
      result = self.wrapNamedKeys("\(vimModifiers)\(vimClickCount)\(vimName)") + vimMouseLocation
    } else {
      result = self.wrapNamedKeys("\(vimClickCount)\(vimName)") + vimMouseLocation
    }

//    NSLog("\(#function): \(result)")
    self.agent.vimInput(result)
  }

  fileprivate func shouldFireVimInputFor(event: NSEvent, newCellPosition: Position) -> Bool {
    let type = event.type
    guard type == .leftMouseDragged || type == .rightMouseDragged || type == .otherMouseDragged else {
      self.lastClickedCellPosition = newCellPosition
      return true
    }

    if self.lastClickedCellPosition == newCellPosition {
      return false
    }

    self.lastClickedCellPosition = newCellPosition
    return true
  }

  fileprivate func vimClickCountFrom(event: NSEvent) -> String {
    let clickCount = event.clickCount

    guard 2 <= clickCount && clickCount <= 4 else {
      return ""
    }

    switch event.type {
    case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp:
      return "\(clickCount)-"
    default:
      return ""
    }
  }

  fileprivate func vimScrollEventNamesFor(deltaX: CGFloat, deltaY: CGFloat) -> (String, String) {
    let typeY: String
    if deltaY > 0 {
      typeY = "ScrollWheelUp"
    } else {
      typeY = "ScrollWheelDown"
    }

    let typeX: String
    if deltaX < 0 {
      typeX = "ScrollWheelRight"
    } else {
      typeX = "ScrollWheelLeft"
    }

    return (typeX, typeY)
  }

  fileprivate func vimScrollInputFor(deltaX: CGFloat, deltaY: CGFloat,
                                     modifierFlags: NSEventModifierFlags,
                                     cellPosition: Position) -> (String, String) {
    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.row),\(cellPosition.column)")

    let (typeX, typeY) = self.vimScrollEventNamesFor(deltaX: deltaX, deltaY: deltaY)
    let resultX: String
    let resultY: String
    if let vimModifiers = self.vimModifierFlags(modifierFlags) {
      resultX = self.wrapNamedKeys("\(vimModifiers)\(typeX)") + vimMouseLocation
      resultY = self.wrapNamedKeys("\(vimModifiers)\(typeY)") + vimMouseLocation
    } else {
      resultX = self.wrapNamedKeys("\(typeX)") + vimMouseLocation
      resultY = self.wrapNamedKeys("\(typeY)") + vimMouseLocation
    }

    return (resultX, resultY)
  }

  fileprivate func throttleScrollX(absDelta absDeltaX: CGFloat, vimInput: String) {
    if absDeltaX == 0 {
      self.scrollGuardCounterX = self.scrollGuardYield - 1
    } else if absDeltaX <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterX % self.scrollGuardYield == 0 {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterX = 1
      } else {
        self.scrollGuardCounterX += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }

  fileprivate func throttleScrollY(absDelta absDeltaY: CGFloat, vimInput: String) {
    if absDeltaY == 0 {
      self.scrollGuardCounterY = self.scrollGuardYield - 1
    } else if absDeltaY <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterY % self.scrollGuardYield == 0 {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterY = 1
      } else {
        self.scrollGuardCounterY += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }
}

// MARK: - NeoVimUiBridgeProtocol
extension NeoVimView {

  public func resize(toWidth width: Int32, height: Int32) {
    DispatchQueue.main.async {
//      NSLog("\(#function): \(width):\(height)")
      self.grid.resize(Size(width: Int(width), height: Int(height)))
      self.markForRenderWholeView()
    }
  }

  public func clear() {
    DispatchQueue.main.async {
      self.grid.clear()
      self.markForRenderWholeView()
    }
  }

  public func eolClear() {
    DispatchQueue.main.async {
      self.grid.eolClear()

      let putPosition = self.grid.putPosition
      let region = Region(top: putPosition.row,
                          bottom: putPosition.row,
                          left: putPosition.column,
                          right: self.grid.region.right)
      self.markForRender(region: region)
    }
  }

  public func gotoPosition(_ position: Position, screenCursor: Position, currentPosition: Position) {
    DispatchQueue.main.async {
      self.currentPosition = currentPosition
//      NSLog("\(#function): \(position), \(screenCursor)")

      let curScreenCursor = self.grid.screenCursor

      // Because neovim fills blank space with "Space" and when we enter "Space" we don't get the puts, thus we have to
      // redraw the put position.
      if self.usesLigatures {
        self.markForRender(region: self.grid.regionOfWord(at: self.grid.putPosition))
        self.markForRender(region: self.grid.regionOfWord(at: curScreenCursor))
        self.markForRender(region: self.grid.regionOfWord(at: position))
        self.markForRender(region: self.grid.regionOfWord(at: screenCursor))
      } else {
        self.markForRender(cellPosition: self.grid.putPosition)
        // Redraw where the cursor has been till now, ie remove the current cursor.
        self.markForRender(cellPosition: curScreenCursor)
        if self.grid.isPreviousCellEmpty(curScreenCursor) {
          self.markForRender(cellPosition: self.grid.previousCellPosition(curScreenCursor))
        }
        if self.grid.isNextCellEmpty(curScreenCursor) {
          self.markForRender(cellPosition: self.grid.nextCellPosition(curScreenCursor))
        }
        self.markForRender(cellPosition: position)
        self.markForRender(cellPosition: screenCursor)
      }

      self.grid.goto(position)
      self.grid.moveCursor(screenCursor)
    }
    DispatchQueue.main.async {
      self.delegate?.cursor(to: currentPosition)
    }
  }

  public func updateMenu() {
  }

  public func busyStart() {
  }

  public func busyStop() {
  }

  public func mouseOn() {
  }

  public func mouseOff() {
  }

  public func modeChange(_ mode: CursorModeShape) {
//    NSLog("mode changed to: %02x", mode.rawValue)
    self.mode = mode
  }

  public func setScrollRegionToTop(_ top: Int32, bottom: Int32, left: Int32, right: Int32) {
    DispatchQueue.main.async {
      let region = Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right))
      self.grid.setScrollRegion(region)
    }
  }

  public func scroll(_ count: Int32) {
    DispatchQueue.main.async {
      self.grid.scroll(Int(count))
      self.markForRender(region: self.grid.region)
      // Do not send msgs to agent -> neovim in the delegate method. It causes spinning when you're opening a file with
      // existing swap file.
      self.delegate?.scroll()
    }
  }

  public func highlightSet(_ attrs: CellAttributes) {
    DispatchQueue.main.async {
      self.grid.attrs = attrs
    }
  }

  public func put(_ string: String, screenCursor: Position) {
    DispatchQueue.main.async {
      let curPos = self.grid.putPosition
//      NSLog("\(#function): \(curPos) -> \(string)")
      self.grid.put(string)

      if self.usesLigatures {
        if string == " " {
          self.markForRender(cellPosition: curPos)
        } else {
          self.markForRender(region: self.grid.regionOfWord(at: curPos))
        }
      } else {
        self.markForRender(cellPosition: curPos)
      }

      self.updateCursorWhenPutting(currentPosition: curPos, screenCursor: screenCursor)
    }
  }

  public func putMarkedText(_ markedText: String, screenCursor: Position) {
    DispatchQueue.main.async {
      NSLog("\(#function): '\(markedText)' -> \(screenCursor)")

      let curPos = self.grid.putPosition
      self.grid.putMarkedText(markedText)

      self.markForRender(position: curPos)
      // When the cursor is in the command line, then we need this...
      self.markForRender(cellPosition: self.grid.nextCellPosition(curPos))
      if markedText.characters.count == 0 {
        self.markForRender(position: self.grid.previousCellPosition(curPos))
      }

      self.updateCursorWhenPutting(currentPosition: curPos, screenCursor: screenCursor)
    }
  }

  public func unmarkRow(_ row: Int32, column: Int32) {
    DispatchQueue.main.async {
      let position = Position(row: Int(row), column: Int(column))

//      NSLog("\(#function): \(position)")

      self.grid.unmarkCell(position)
      self.markForRender(position: position)

      self.markForRender(screenCursor: self.grid.screenCursor)
    }
  }

  public func bell() {
    DispatchQueue.main.async {
      NSBeep()
    }
  }

  public func visualBell() {
  }

  public func flush() {
  }

  public func updateForeground(_ fg: Int32) {
    DispatchQueue.main.async {
      self.grid.foreground = UInt32(bitPattern: fg)
//      NSLog("\(ColorUtils.colorIgnoringAlpha(UInt32(fg)))")
    }
  }

  public func updateBackground(_ bg: Int32) {
    DispatchQueue.main.async {
      self.grid.background = UInt32(bitPattern: bg)
      self.layer?.backgroundColor = ColorUtils.colorIgnoringAlpha(self.grid.background).cgColor
//      NSLog("\(ColorUtils.colorIgnoringAlpha(UInt32(bg)))")
    }
  }

  public func updateSpecial(_ sp: Int32) {
    DispatchQueue.main.async {
      self.grid.special = UInt32(bitPattern: sp)
    }
  }

  public func suspend() {
  }

  public func setTitle(_ title: String) {
    DispatchQueue.main.async {
      self.delegate?.set(title: title)
    }
  }

  public func setIcon(_ icon: String) {
  }

  public func stop() {
    DispatchQueue.main.async {
      self.delegate?.neoVimStopped()
    }
    self.agent.quit()
  }

  public func setDirtyStatus(_ dirty: Bool) {
    DispatchQueue.main.async {
      self.delegate?.set(dirtyStatus: dirty)
    }
  }

  public func autoCommandEvent(_ event: NeoVimAutoCommandEvent, bufferHandle: Int) {
    DispatchQueue.main.async {
//    NSLog("\(event.rawValue) with buffer \(bufferHandle)")

      if event == .BUFWINENTER || event == .BUFWINLEAVE {
        self.bufferListChanged()
      }

      if event == .TABENTER {
        self.tabChanged()
      }

      if event == .DIRCHANGED {
        self.cwdChanged()
      }

      if event == .BUFREADPOST || event == .BUFWRITEPOST {
        self.currentBufferChanged(bufferHandle)
      }
    }
  }

  public func ipcBecameInvalid(_ reason: String) {
    DispatchQueue.main.async {
      if self.agent.neoVimIsQuitting {
        return
      }

      self.delegate?.ipcBecameInvalid(reason: reason)

      NSLog("ERROR \(#function): force-quitting")
      self.agent.quit()
    }
  }

  fileprivate func currentBufferChanged(_ handle: Int) {
    guard let currentBuffer = self.currentBuffer() else {
      return
    }

    guard currentBuffer.handle == handle else {
      return
    }

    self.delegate?.currentBufferChanged(currentBuffer)
  }

  fileprivate func tabChanged() {
    self.delegate?.tabChanged()
  }

  fileprivate func cwdChanged() {
    self.delegate?.cwdChanged()
  }

  fileprivate func bufferListChanged() {
    self.delegate?.bufferListChanged()
  }

  fileprivate func updateCursorWhenPutting(currentPosition curPos: Position, screenCursor: Position) {
    if self.mode == .cmdline {
      // When the cursor is in the command line, then we need this...
      self.markForRender(cellPosition: self.grid.previousCellPosition(curPos))
      self.markForRender(cellPosition: self.grid.nextCellPosition(curPos))
      self.markForRender(screenCursor: self.grid.screenCursor)
    }

    self.markForRender(screenCursor: screenCursor)
    self.markForRender(cellPosition: self.grid.screenCursor)
    self.grid.moveCursor(screenCursor)
  }

  fileprivate func markForRender(cellPosition position: Position) {
    self.markForRender(position: position)

    if self.grid.isCellEmpty(position) {
      self.markForRender(position: self.grid.previousCellPosition(position))
    }

    if self.grid.isNextCellEmpty(position) {
      self.markForRender(position: self.grid.nextCellPosition(position))
    }
  }

  fileprivate func markForRender(position: Position) {
    self.markForRender(row: position.row, column: position.column)
  }

  fileprivate func markForRender(screenCursor position: Position) {
    self.markForRender(position: position)
    if self.grid.isNextCellEmpty(position) {
      self.markForRender(position: self.grid.nextCellPosition(position))
    }
  }

  fileprivate func markForRenderWholeView() {
    self.needsDisplay = true
  }

  fileprivate func markForRender(region: Region) {
    self.setNeedsDisplay(self.regionRectFor(region: region))
  }

  fileprivate func markForRender(row: Int, column: Int) {
    self.setNeedsDisplay(self.cellRectFor(row: row, column: column))
  }
}
