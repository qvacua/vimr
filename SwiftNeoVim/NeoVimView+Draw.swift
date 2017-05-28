/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView {

  override public func viewDidMoveToWindow() {
    self.window?.colorSpace = colorSpace
  }

  override public func draw(_ dirtyUnionRect: NSRect) {
    guard self.grid.hasData else {
      return
    }

    guard let viewCtx = NSGraphicsContext.current()?.cgContext else {
      self.logger.error("Could not get the current CGContext of the view.")
      return
    }

    guard let bufferLayer = self.bufferLayer else {
      self.logger.error("Could not get the buffer CGLayer.")
      return
    }

    guard let bufferCtx = self.bufferContext else {
      self.logger.error("Could not get the buffer CGContext (of the buffer CGLayer).")
      return
    }

    viewCtx.saveGState()
    defer { viewCtx.restoreGState() }

    bufferCtx.saveGState()
    defer { bufferCtx.restoreGState() }

    if self.inLiveResize || self.currentlyResizing {
      self.drawResizeInfo(in: viewCtx, with: dirtyUnionRect)
      return
    }

    if self.isCurrentlyPinching {
      self.drawPinchImage(in: viewCtx)
      return
    }

    let dirtyRects = self.rectsBeingDrawn()

    self.logger.debug("dirty union rect: \(dirtyUnionRect)")
    self.logger.debug("rects being drawn: \(dirtyRects)")

    let scale = self.scaleFactor
    let boundsSize = self.bounds.size
    let layerSize = bufferLayer.size.scaling(1 / scale)

    let drawRect = CGRect(x: 0,
                          y: boundsSize.height - layerSize.height,
                          width: layerSize.width,
                          height: layerSize.height)

    bufferCtx.scaleBy(x: scale, y: scale)
    dirtyRects.forEach {
      viewCtx.saveGState()
      viewCtx.clip(to: $0)
      viewCtx.setBlendMode(.copy)
      viewCtx.draw(bufferLayer, in: drawRect)
      viewCtx.restoreGState()
    }
  }

  func draw(rowRun rowFrag: RowRun, in context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    // When both anti-aliasing and font smoothing is turned on, then the "Use LCD font smoothing
    // when available" setting is used to render texts,
    // cf. chapter 11 from "Programming with Quartz".
    context.setShouldSmoothFonts(true);
    context.textMatrix = .identity;
    context.setTextDrawingMode(.fill);

    // For background drawing we don't filter out the put(0, 0)s:
    // in some cases only the put(0, 0)-cells should be redrawn.
    // => FIXME: probably we have to consider this also when drawing further down,
    // ie when the range starts with '0'...
    self.drawBackground(
      positions: rowFrag.range.map { self.pointInView(forRow: rowFrag.row, column: $0) },
      background: rowFrag.attrs.background,
      in: context
    )

    let positions = rowFrag.range
      // filter out the put(0, 0)s (after a wide character)
      .filter { self.grid.cells[rowFrag.row][$0].string.characters.count > 0 }
      .map { self.pointInView(forRow: rowFrag.row, column: $0) }

    if positions.isEmpty {
      return
    }

    let string = self.grid.cells[rowFrag.row][rowFrag.range].reduce("") { $0 + $1.string }
    let offset = self.drawer.baselineOffset
    let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + offset) }

    self.drawer.draw(
      string,
      positions: UnsafeMutablePointer(mutating: glyphPositions), positionsCount: positions.count,
      highlightAttrs: rowFrag.attrs,
      context: context
    )
  }

  fileprivate func cursorRegion() -> Region {
    let cursorPosition: Position
    if self.mode == .cmdline
       || self.mode == .cmdlineInsert
       || self.mode == .cmdlineReplace {
      cursorPosition = self.grid.putPosition
    } else {
      cursorPosition = self.grid.screenCursor
    }

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
    context.saveGState()
    defer { context.restoreGState() }

    let cursorRegion = self.cursorRegion()
    let cursorRow = cursorRegion.top
    let cursorColumnStart = cursorRegion.left

    if self.mode == .insert {
      context.setFillColor(ColorUtils.colorIgnoringAlpha(self.grid.foreground).withAlphaComponent(0.75).cgColor)
      var cursorRect = self.rect(forRow: cursorRow, column: cursorColumnStart)
      cursorRect.size.width = 2
      context.fill(cursorRect)
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
    self.draw(rowRun: rowRun, in: context)
  }

  fileprivate func drawBackground(positions: [CGPoint], background: Int, in context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    context.setFillColor(ColorUtils.colorIgnoringAlpha(background).cgColor)
    // To use random color use the following
//    NSColor(calibratedRed: CGFloat(drand48()),
//            green: CGFloat(drand48()),
//            blue: CGFloat(drand48()),
//            alpha: 1.0).set()

    let backgroundRect = CGRect(
      x: positions[0].x, y: positions[0].y,
      width: CGFloat(positions.count) * self.cellSize.width, height: self.cellSize.height
    )
    context.fill(backgroundRect)
  }

  fileprivate func drawResizeInfo(in context: CGContext, with dirtyUnionRect: CGRect) {
    context.setFillColor(NSColor.windowBackgroundColor.cgColor)
    context.fill(dirtyUnionRect)

    let boundsSize = self.bounds.size

    let emojiSize = self.currentEmoji.size(withAttributes: emojiAttrs)
    let emojiX = (boundsSize.width - emojiSize.width) / 2
    let emojiY = (boundsSize.height - emojiSize.height) / 2

    let discreteSize = self.discreteSize(size: boundsSize)
    let displayStr = "\(discreteSize.width) × \(discreteSize.height)"

    let size = displayStr.size(withAttributes: resizeTextAttrs)
    let x = (boundsSize.width - size.width) / 2
    let y = emojiY - size.height

    self.currentEmoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
    displayStr.draw(at: CGPoint(x: x, y: y), withAttributes: resizeTextAttrs)
  }

  fileprivate func drawPinchImage(in context: CGContext) {
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
  }

  func rowRunIntersecting(rects: [CGRect]) -> [RowRun] {
    return rects
      .map { rect -> (CountableClosedRange<Int>, CountableClosedRange<Int>) in
        // Get all Regions that intersects with the given rects.
        // There can be overlaps between the Regions, but for the time being we ignore them;
        // probably not necessary to optimize them away.
        let region = self.regionFor(rect: rect)
        return (region.rowRange, region.columnRange)
      }
      // All RowRuns for all Regions grouped by their row range.
      .map { self.rowRunsFor(rowRange: $0, columnRange: $1) }
      // Flattened RowRuns for all Regions.
      .flatMap { $0 }
  }

  fileprivate func rowRunsFor(rowRange: CountableClosedRange<Int>,
                              columnRange: CountableClosedRange<Int>) -> [RowRun] {

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
      Int(floor(
        (self.bounds.height - self.yOffset - (rect.origin.y + rect.size.height)) / cellHeight)
      ), 0
    )
    let rowEnd = min(
      Int(ceil((self.bounds.height - self.yOffset - rect.origin.y) / cellHeight)) - 1,
      self.grid.size.height - 1
    )
    let columnStart = max(
      Int(floor((rect.origin.x - self.xOffset) / cellWidth)), 0
    )
    let columnEnd = min(
      Int(ceil((rect.origin.x - self.xOffset + rect.size.width) / cellWidth)) - 1,
      self.grid.size.width - 1
    )

    if rowStart > rowEnd || columnStart > columnEnd {
      self.bridgeLogger.debug("\(rowStart):\(rowEnd)_\(columnStart):\(columnEnd) Out of range")
      return .zero
    }

    return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
  }

  fileprivate func pointInViewFor(position: Position) -> CGPoint {
    return self.pointInView(forRow: position.row, column: position.column)
  }

  fileprivate func pointInView(forRow row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: self.xOffset + CGFloat(column) * self.cellSize.width,
      y: self.bounds.size.height - self.yOffset - CGFloat(row) * self.cellSize.height
         - self.cellSize.height
    )
  }

  func rect(forRow row: Int, column: Int) -> CGRect {
    return CGRect(origin: self.pointInView(forRow: row, column: column), size: self.cellSize)
  }

  func rect(for region: Region) -> CGRect {
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

  func wrapNamedKeys(_ string: String) -> String {
    return "<\(string)>"
  }

  func vimPlainString(_ string: String) -> String {
    return string.replacingOccurrences(of: "<", with: self.wrapNamedKeys("lt"))
  }

  func updateFontMetaData(_ newFont: NSFont) {
    self.drawer.font = newFont

    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    self.resizeNeoVimUi(to: self.bounds.size)
  }
}

fileprivate let emojiAttrs = [ NSFontAttributeName: NSFont(name: "AppleColorEmoji", size: 72)! ]
fileprivate let resizeTextAttrs = [
  NSFontAttributeName: NSFont.systemFont(ofSize: 18),
  NSForegroundColorAttributeName: NSColor.darkGray
]
fileprivate let colorSpace = NSColorSpace.sRGB
