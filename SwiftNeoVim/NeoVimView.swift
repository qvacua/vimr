/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

enum Mode {
  /*
#define NORMAL          0x01    /* Normal mode, command expected */
#define VISUAL          0x02    /* Visual mode - use get_real_state() */
#define OP_PENDING      0x04    /* Normal mode, operator is pending - use
                                   get_real_state() */
#define CMDLINE         0x08    /* Editing command line */
#define INSERT          0x10    /* Insert mode */
#define LANGMAP         0x20    /* Language mapping, can be combined with
                                   INSERT and CMDLINE */

#define REPLACE_FLAG    0x40    /* Replace mode flag */
#define REPLACE         (REPLACE_FLAG + INSERT)
# define VREPLACE_FLAG  0x80    /* Virtual-replace mode flag */
# define VREPLACE       (REPLACE_FLAG + VREPLACE_FLAG + INSERT)
#define LREPLACE        (REPLACE_FLAG + LANGMAP)

#define NORMAL_BUSY     (0x100 + NORMAL) /* Normal mode, busy with a command */
#define HITRETURN       (0x200 + NORMAL) /* waiting for return or command */
#define ASKMORE         0x300   /* Asking if you want --more-- */
#define SETWSIZE        0x400   /* window size has changed */
#define ABBREV          0x500   /* abbreviation instead of mapping */
#define EXTERNCMD       0x600   /* executing an external command */
#define SHOWMATCH       (0x700 + INSERT) /* show matching paren */
#define CONFIRM         0x800   /* ":confirm" prompt */
#define SELECTMODE      0x1000  /* Select mode, only for mappings */
#define TERM_FOCUS      0x2000  // Terminal focus mode

// all mode bits used for mapping
#define MAP_ALL_MODES   (0x3f | SELECTMODE | TERM_FOCUS)

  */

}

/// Contiguous piece of cells of a row that has the same attributes.
private struct RowRun: CustomStringConvertible {

  let row: Int
  let range: Range<Int>
  let attrs: CellAttributes

  var description: String {
    return "RowRun<\(row): \(range)\n\(attrs)>"
  }
}

public class NeoVimView: NSView {
  
  public let uuid = NSUUID().UUIDString
  public var delegate: NeoVimViewDelegate?
  
  let agent: NeoVimAgent

  let grid = Grid()

  var markedText: String?
  /// We store the last marked text because Cocoa's text input system does the following:
  /// 하 -> hanja popup -> insertText(하) -> attributedSubstring...() -> setMarkedText(下) -> ...
  /// We want to return "하" in attributedSubstring...()
  var lastMarkedText: String?
  
  var markedPosition = Position.null
  var keyDownDone = true
  
  var xOffset = CGFloat(0)
  var yOffset = CGFloat(0)
  var cellSize = CGSize.zero
  var descent = CGFloat(0)
  var leading = CGFloat(0)

  private let drawer: TextDrawer
  private var font: NSFont {
    didSet {
      self.drawer.font = self.font
      self.cellSize = self.drawer.cellSize
      self.descent = self.drawer.descent
      self.leading = self.drawer.leading
      
      // We assume that the font is valid, eg fixed width, not too small, not too big, etc..
      self.resizeNeoVimUiTo(size: self.frame.size)
    }
  }
  
  override init(frame rect: NSRect = CGRect.zero) {
    self.font = NSFont(name: "Menlo", size: 16)!
    self.drawer = TextDrawer(font: font)
    self.agent = NeoVimAgent(uuid: self.uuid)
    
    super.init(frame: rect)
    
    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    // We cannot set bridge in init since self is not available before super.init()...
    self.agent.bridge = self
    self.agent.establishLocalServer()
  }

  // deinit would have been ideal for this, but if you quit the app, deinit does not necessarily get called...
  public func cleanUp() {
    self.agent.cleanUp()
  }

  public func debugInfo() {
    Swift.print(self.grid)
  }

  public func setFont(font: NSFont) {
    guard font.fixedPitch else {
      return
    }

    // FIXME: check the size whether too small or too big!
    self.font = font
  }

  override public func setFrameSize(newSize: NSSize) {
    super.setFrameSize(newSize)

    // initial resizing is done when grid has data
    guard self.grid.hasData else {
      return
    }

    if self.inLiveResize {
      // TODO: Turn of live resizing for now.
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

  func resizeNeoVimUiTo(size size: CGSize) {
//    NSLog("\(#function): \(size)")
    let discreteSize = Size(width: Int(floor(size.width / self.cellSize.width)),
                            height: Int(floor(size.height / self.cellSize.height)))

    self.xOffset = floor((size.width - self.cellSize.width * CGFloat(discreteSize.width)) / 2)
    self.yOffset = floor((size.height - self.cellSize.height * CGFloat(discreteSize.height)) / 2)

    self.agent.resizeToWidth(Int32(discreteSize.width), height: Int32(discreteSize.height))
  }

  override public func drawRect(dirtyUnionRect: NSRect) {
    guard self.grid.hasData else {
      return
    }

    if self.inLiveResize {
      NSColor.lightGrayColor().set()
      dirtyUnionRect.fill()
      return
    }

//    NSLog("\(#function): \(dirtyUnionRect)")
    let context = NSGraphicsContext.currentContext()!.CGContext

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextDrawingMode(context, .Fill);

    let dirtyRects = self.rectsBeingDrawn()

    self.rowRunIntersecting(rects: dirtyRects).forEach { rowFrag in
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
      let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + self.descent + self.leading) }
      self.drawer.drawString(string,
                             positions: UnsafeMutablePointer(glyphPositions), positionsCount: positions.count,
                             highlightAttrs: rowFrag.attrs,
                             context: context)
    }

    self.drawCursor(self.grid.background)
  }

  private func drawCursor(background: UInt32) {
    // FIXME: for now do some rudimentary cursor drawing
    let cursorPosition = self.grid.screenCursor
//    Swift.print("\(#function): \(cursorPosition)")

    var cursorRect = self.cellRectFor(row: cursorPosition.row, column: cursorPosition.column)
    if self.grid.isNextCellEmpty(cursorPosition) {
      let nextPosition = self.grid.nextCellPosition(cursorPosition)
      cursorRect = cursorRect.union(self.cellRectFor(row: nextPosition.row, column:nextPosition.column))
    }

    ColorUtils.colorIgnoringAlpha(background).set()
    NSRectFillUsingOperation(cursorRect, .CompositeDifference)
  }

  private func drawBackground(positions positions: [CGPoint], background: UInt32) {
    ColorUtils.colorIgnoringAlpha(background).set()
    let backgroundRect = CGRect(
      x: positions[0].x, y: positions[0].y,
      width: positions.last!.x + self.cellSize.width, height: self.cellSize.height
    )
    backgroundRect.fill()
  }

  private func rowRunIntersecting(rects rects: [CGRect]) -> [RowRun] {
    return rects
      .map { rect -> (Range<Int>, Range<Int>) in
        // Get all Regions that intersects with the given rects. There can be overlaps between the Regions, but for the
        // time being we ignore them; probably not necessary to optimize them away.
        let region = self.regionFor(rect: rect)
        return (region.rowRange, region.columnRange)
      }
      .map { self.rowRunsFor(rowRange: $0, columnRange: $1) } // All RowRuns for all Regions grouped by their row range.
      .flatMap { $0 }                                         // Flattened RowRuns for all Regions.
  }

  private func rowRunsFor(rowRange rowRange: Range<Int>, columnRange: Range<Int>) -> [RowRun] {
    return rowRange
      .map { (row) -> [RowRun] in
        let rowCells = self.grid.cells[row]
        let startIdx = columnRange.startIndex

        var result = [ RowRun(row: row, range: startIdx...startIdx, attrs: rowCells[startIdx].attrs) ]
        columnRange.forEach { idx in
          if rowCells[idx].attrs == result.last!.attrs {
            let last = result.popLast()!
            result.append(RowRun(row: row, range: last.range.startIndex...idx, attrs: last.attrs))
          } else {
            result.append(RowRun(row: row, range: idx...idx, attrs: rowCells[idx].attrs))
          }
        }

        return result // All RowRuns for a row in a Region.
      }               // All RowRuns for all rows in a Region grouped by row.
      .flatMap { $0 } // Flattened RowRuns for a Region.
  }

  private func regionFor(rect rect: CGRect) -> Region {
    let rowStart = max(
      Int(floor((self.frame.height - (rect.origin.y + rect.size.height)) / self.cellSize.height)), 0
    )
    let rowEnd = min(
      Int(ceil((self.frame.height - rect.origin.y) / self.cellSize.height)) - 1, self.grid.size.height  - 1
    )
    let columnStart = max(
      Int(floor(rect.origin.x / self.cellSize.width)), 0
    )
    let columnEnd = min(
      Int(ceil((rect.origin.x + rect.size.width) / self.cellSize.width)) - 1, self.grid.size.width - 1
    )

    return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
  }
  
  func pointInViewFor(position position: Position) -> CGPoint {
    return self.pointInViewFor(row: position.row, column: position.column)
  }

  func pointInViewFor(row row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column) * self.cellSize.width + self.xOffset,
      y: self.frame.size.height - CGFloat(row) * self.cellSize.height - self.cellSize.height - self.yOffset
    )
  }

  func cellRectFor(row row: Int, column: Int) -> CGRect {
    return CGRect(origin: self.pointInViewFor(row: row, column: column), size: self.cellSize)
  }

  func regionRectFor(region region: Region) -> CGRect {
    let top = CGFloat(region.top)
    let bottom = CGFloat(region.bottom)
    let left = CGFloat(region.left)
    let right = CGFloat(region.right)

    let width = right - left + 1
    let height = bottom - top + 1

    return CGRect(
      x: left * self.cellSize.width + self.xOffset,
      y: (CGFloat(self.grid.size.height) - bottom) * self.cellSize.height - self.yOffset,
      width: width * self.cellSize.width,
      height: height * self.cellSize.height
    )
  }

  func vimNamedKeys(string: String) -> String {
    return "<\(string)>"
  }
  
  func vimPlainString(string: String) -> String {
    return string.stringByReplacingOccurrencesOfString("<", withString: self.vimNamedKeys("lt"))
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

