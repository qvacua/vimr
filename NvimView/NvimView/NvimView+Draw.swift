/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NvimView {

  override public func viewDidMoveToWindow() {
    self.window?.colorSpace = colorSpace
  }

  override public func draw(_ dirtyUnionRect: NSRect) {
    guard self.ugrid.hasData else {
      return
    }

    let context = NSGraphicsContext.current!.cgContext
    context.saveGState()
    defer { context.restoreGState() }

    if (self.inLiveResize || self.currentlyResizing) && !self.usesLiveResize {
      self.drawResizeInfo(in: context, with: dirtyUnionRect)
      return
    }

    if self.isCurrentlyPinching {
      self.drawPinchImage(in: context)
      return
    }

    // When both anti-aliasing and font smoothing is turned on, then the "Use LCD font smoothing
    // when available" setting is used to render texts,
    // cf. chapter 11 from "Programming with Quartz".
    context.setShouldSmoothFonts(true);
    context.setTextDrawingMode(.fill);

    let dirtyRects = self.rectsBeingDrawn()
    ColorUtils.colorIgnoringAlpha(
      self.cellAttributesCollection.defaultAttributes.background
    ).set()
    dirtyRects.fill()

    self.runs(intersecting: dirtyRects).forEach { row in
      self.draw(row, in: context)
    }
//    self.drawCursor(context: context)

//    self.draw(cellGridIn: context)
  }

  private func draw(cellGridIn context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    let color = NSColor.magenta.cgColor
    context.setFillColor(color)

    let discreteSize = self.discreteSize(size: self.bounds.size)
    var lines = [
      CGRect(x: 0 + self.xOffset, y: 0, width: 1, height: self.bounds.height),
      CGRect(
        x: self.bounds.width - 1 + self.xOffset,
        y: 0,
        width: 1,
        height: self.bounds.height
      ),
      CGRect(
        x: 0,
        y: self.bounds.height - 1 - self.yOffset,
        width: self.bounds.width,
        height: 1
      ),
      CGRect(
        x: 0,
        y: self.bounds.height - 1 - self.yOffset
          - CGFloat(discreteSize.height) * self.self.cellSize.height,
        width: self.bounds.width,
        height: 1
      ),
    ]

    for row in 0...discreteSize.height {
      for col in 0...discreteSize.width {
        lines.append(contentsOf: [
          CGRect(
            x: CGFloat(col) * self.cellSize.width + self.xOffset - 1,
            y: 0,
            width: 1,
            height: self.bounds.height
          ),
          CGRect(
            x: 0,
            y: self.bounds.height - 1
              - self.yOffset - CGFloat(row) * self.self.cellSize.height,
            width: self.bounds.width,
            height: 1
          ),
        ])
      }
    }

    lines.forEach { $0.fill() }
  }

  private func draw(_ run: AttributesRun, in context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    self.runDrawer.draw(
      run,
      with: self.cellAttributesCollection.defaultAttributes,
      xOffset: self.xOffset,
      in: context
    )
  }

  private func cursorRegion() -> Region {
    let cursorPosition = self.grid.position

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

  private func drawCursor(context: CGContext) {
    guard self.shouldDrawCursor else {
      return
    }

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
//    let attrsAtCursor = self.grid.cells[cursorRow][cursorColumnStart].attrs
//    let attrs = CellAttributes(fontTrait: attrsAtCursor.fontTrait,
//                               foreground: self.grid.background,
//                               background: self.grid.foreground,
//                               special: self.grid.special)

    // FIXME: take ligatures into account (is it a good idea to do this?)
//    let rowRun = RowRun(row: cursorRegion.top, range: cursorRegion.columnRange, attrs: attrs)
//    self.draw(rowRun: rowRun, in: context)

    self.shouldDrawCursor = false
  }

  private func drawResizeInfo(in context: CGContext, with dirtyUnionRect: CGRect) {
    context.setFillColor(self.theme.background.cgColor)
    context.fill(dirtyUnionRect)

    let boundsSize = self.bounds.size

    let emojiSize = self.currentEmoji.size(withAttributes: emojiAttrs)
    let emojiX = (boundsSize.width - emojiSize.width) / 2
    let emojiY = (boundsSize.height - emojiSize.height) / 2

    let discreteSize = self.discreteSize(size: boundsSize)
    let displayStr = "\(discreteSize.width) × \(discreteSize.height)"
    let infoStr = "(You can turn on the experimental live resizing feature in the Advanced preferences)"

    var (sizeAttrs, infoAttrs) = (resizeTextAttrs, infoTextAttrs)
    sizeAttrs[.foregroundColor] = self.theme.foreground
    infoAttrs[.foregroundColor] = self.theme.foreground

    let size = displayStr.size(withAttributes: sizeAttrs)
    let (x, y) = ((boundsSize.width - size.width) / 2, emojiY - size.height)

    let infoSize = infoStr.size(withAttributes: infoAttrs)
    let (infoX, infoY) = ((boundsSize.width - infoSize.width) / 2, y - size.height - 5)

    self.currentEmoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
    displayStr.draw(at: CGPoint(x: x, y: y), withAttributes: sizeAttrs)
    infoStr.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: infoAttrs)
  }

  private func drawPinchImage(in context: CGContext) {
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

  private func runs(intersecting rects: [CGRect]) -> [AttributesRun] {
    return rects
      .map { rect in
        // Get all Regions that intersects with the given rects.
        // There can be overlaps between the Regions,
        // but for the time being we ignore them;
        // probably not necessary to optimize them away.
        let region = self.region(for: rect)
        return (region.rowRange, region.columnRange)
      }
      // All RowRuns for all Regions grouped by their row range.
      .map { self.runs(forRowRange: $0, columnRange: $1) }
      // Flattened RowRuns for all Regions.
      .flatMap { $0 }
  }

  private func runs(
    forRowRange rowRange: CountableClosedRange<Int>,
    columnRange: CountableClosedRange<Int>
  ) -> [AttributesRun] {

    return rowRange.map { row in
        self.ugrid.cells[row]
          .groupedRanges(with: { _, cell, _ in cell.attrId })
          .compactMap { range in
            let cells = self.ugrid.cells[row][range]

            guard let firstCell = cells.first,
                  let attrs = self.cellAttributesCollection.attributes(
                    of: firstCell.attrId
                  )
              else {
              // GH-666: FIXME: correct error handling
              self.logger.error("row: \(row), range: \(range): " +
                                  "Could not get CellAttributes with ID " +
                                  "\(cells.first?.attrId)")
              return nil
            }

            return AttributesRun(
              location: self.pointInView(forRow: row, column: range.lowerBound),
              cells: self.ugrid.cells[row][range],
              attrs: attrs
            )
          }
      }
      .flatMap { $0 }
  }

  private func region(for rect: CGRect) -> Region {
    let cellWidth = self.cellSize.width
    let cellHeight = self.cellSize.height

    let rowStart = max(
      0,
      Int(floor(
        (self.bounds.height - self.yOffset
          - (rect.origin.y + rect.size.height)) / cellHeight
      ))
    )
    let rowEnd = min(
      self.ugrid.size.height - 1,
      Int(ceil(
        (self.bounds.height - self.yOffset - rect.origin.y) / cellHeight
      )) - 1
    )
    let columnStart = max(
      0,
      Int(floor((rect.origin.x - self.xOffset) / cellWidth))
    )
    let columnEnd = min(
      self.ugrid.size.width - 1,
      Int(ceil(
        (rect.origin.x - self.xOffset + rect.size.width) / cellWidth
      )) - 1
    )

    return Region(
      top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd
    )
  }

  private func pointInView(forRow row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: self.xOffset + CGFloat(column) * self.cellSize.width,
      y: self.bounds.size.height - self.yOffset
        - CGFloat(row) * self.cellSize.height - self.cellSize.height
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
    self.runDrawer.baseFont = newFont

    self.cellSize = FontUtils.cellSize(
      of: newFont, linespacing: self.linespacing
    )
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    self.resizeNeoVimUi(to: self.bounds.size)
  }
}

private let emojiAttrs = [NSAttributedStringKey.font: NSFont(name: "AppleColorEmoji", size: 72)!]

private let resizeTextAttrs = [
  NSAttributedStringKey.font: NSFont.systemFont(ofSize: 18),
  NSAttributedStringKey.foregroundColor: NSColor.darkGray
]

private let infoTextAttrs = [
  NSAttributedStringKey.font: NSFont.systemFont(ofSize: 16),
  NSAttributedStringKey.foregroundColor: NSColor.darkGray
]

private let colorSpace = NSColorSpace.sRGB
