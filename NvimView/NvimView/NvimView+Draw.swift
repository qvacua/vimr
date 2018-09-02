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
    guard self.ugrid.hasData else { return }

    guard let context = NSGraphicsContext.current?.cgContext else { return }
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

    // When both anti-aliasing and font smoothing is turned on,
    // then the "Use LCD font smoothing when available" setting is used
    // to render texts, cf. chapter 11 from "Programming with Quartz".
    context.setShouldSmoothFonts(true);
    context.setTextDrawingMode(.fill);

    let dirtyRects = self.rectsBeingDrawn()

    self.draw(defaultBackgroundIn: dirtyRects, in: context)

#if DEBUG
    self.draw(textByParallelComputationIntersecting: dirtyRects, in: context)
#else
    self.draw(intersecting: dirtyRects, in: context)
#endif

    self.drawCursor(in: context)

#if DEBUG
    // self.draw(cellGridIn: context)
#endif
  }

  private func draw(
    defaultBackgroundIn dirtyRects: [CGRect], `in` context: CGContext
  ) {
    context.setFillColor(
      ColorUtils.cgColorIgnoringAlpha(
        self.cellAttributesCollection.defaultAttributes.background
      )
    )
    context.fill(dirtyRects)
  }

  private func draw(
    textByParallelComputationIntersecting dirtyRects: [CGRect],
    `in` context: CGContext
  ) {
    let attrsRuns = self.runs(intersecting: dirtyRects)
    let runs = attrsRuns.parallelMap {
      run -> (attrsRun: AttributesRun, fontGlyphRuns: [FontGlyphRun]) in

      let font = FontUtils.font(adding: run.attrs.fontTrait, to: self.font)

      let fontGlyphRuns = self.typesetter.fontGlyphRunsWithLigatures(
        nvimUtf16Cells: run.cells.map { Array($0.string.utf16) },
        startColumn: run.cells.startIndex,
        offset: CGPoint(
          x: self.xOffset, y: run.location.y + self.baselineOffset
        ),
        font: font,
        cellWidth: self.cellSize.width
      )

      return (attrsRun: run, fontGlyphRuns: fontGlyphRuns)
    }

    let defaultAttrs = self.cellAttributesCollection.defaultAttributes
    runs.forEach { (attrsRun, fontGlyphRuns) in
      self.runDrawer.draw(
        attrsRun,
        fontGlyphRuns: fontGlyphRuns,
        defaultAttributes: defaultAttrs,
        in: context
      )
    }
  }

  private func draw(
    intersecting dirtyRects: [CGRect], `in` context: CGContext
  ) {
    let attrsRuns = self.runs(intersecting: dirtyRects)
    let runs = attrsRuns.map(self.fontGlyphRuns)

    let defaultAttrs = self.cellAttributesCollection.defaultAttributes
    for i in 0..<attrsRuns.count {
      self.runDrawer.draw(
        attrsRuns[i],
        fontGlyphRuns: runs[i],
        defaultAttributes: defaultAttrs,
        in: context
      )
    }
  }

  private func fontGlyphRuns(from attrsRun: AttributesRun) -> [FontGlyphRun] {
    let font = FontUtils.font(adding: attrsRun.attrs.fontTrait, to: self.font)

    let fontGlyphRuns = self.typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: attrsRun.cells.map { Array($0.string.utf16) },
      startColumn: attrsRun.cells.startIndex,
      offset: CGPoint(
        x: self.xOffset, y: attrsRun.location.y + self.baselineOffset
      ),
      font: font,
      cellWidth: self.cellSize.width
    )

    return fontGlyphRuns
  }

  private func drawCursor(`in` context: CGContext) {
    guard self.shouldDrawCursor else {
      return
    }

    context.saveGState()
    defer { context.restoreGState() }

    let cursorPosition = self.ugrid.cursorPosition
    let defaultAttrs = self.cellAttributesCollection.defaultAttributes

    if self.mode == .insert {
      context.setFillColor(
        ColorUtils.cgColorIgnoringAlpha(defaultAttrs.foreground)
      )
      var cursorRect = self.rect(
        forRow: cursorPosition.row, column: cursorPosition.column
      )
      cursorRect.size.width = 2
      context.fill(cursorRect)
      return
    }

    let cursorRegion = self.cursorRegion(for: self.ugrid.cursorPosition)
    guard let cursorAttrs = self.cellAttributesCollection.attributes(
      of: self.ugrid.cells[cursorPosition.row][cursorPosition.column].attrId
    )?.reversed else {
      stdoutLogger.error("Could not get the attributes" +
                           " at cursor: \(cursorPosition)")
      return
    }

    let attrsRun = AttributesRun(
      location: self.pointInView(
        forRow: cursorPosition.row, column: cursorPosition.column
      ),
      cells: self.ugrid.cells[cursorPosition.row][cursorRegion.columnRange],
      attrs: cursorAttrs
    )
    self.runDrawer.draw(
      attrsRun,
      fontGlyphRuns: self.fontGlyphRuns(from: attrsRun),
      defaultAttributes: defaultAttrs,
      in: context
    )

    self.shouldDrawCursor = false
  }

  private func drawResizeInfo(
    in context: CGContext, with dirtyUnionRect: CGRect
  ) {
    context.setFillColor(self.theme.background.cgColor)
    context.fill(dirtyUnionRect)

    let boundsSize = self.bounds.size

    let emojiSize = self.currentEmoji.size(withAttributes: emojiAttrs)
    let emojiX = (boundsSize.width - emojiSize.width) / 2
    let emojiY = (boundsSize.height - emojiSize.height) / 2

    let discreteSize = self.discreteSize(size: boundsSize)
    let displayStr = "\(discreteSize.width) × \(discreteSize.height)"
    let infoStr = "(You can turn on the experimental live resizing feature" +
      " in the Advanced preferences)"

    var (sizeAttrs, infoAttrs) = (resizeTextAttrs, infoTextAttrs)
    sizeAttrs[.foregroundColor] = self.theme.foreground
    infoAttrs[.foregroundColor] = self.theme.foreground

    let size = displayStr.size(withAttributes: sizeAttrs)
    let (x, y) = ((boundsSize.width - size.width) / 2, emojiY - size.height)

    let infoSize = infoStr.size(withAttributes: infoAttrs)
    let (infoX, infoY) = (
      (boundsSize.width - infoSize.width) / 2, y - size.height - 5
    )

    self.currentEmoji.draw(
      at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs
    )
    displayStr.draw(at: CGPoint(x: x, y: y), withAttributes: sizeAttrs)
    infoStr.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: infoAttrs)
  }

  private func drawPinchImage(in context: CGContext) {
    context.interpolationQuality = .none

    let boundsSize = self.bounds.size
    let targetSize = CGSize(width: boundsSize.width * self.pinchTargetScale,
                            height: boundsSize.height * self.pinchTargetScale)
    self.pinchBitmap?.draw(
      in: CGRect(origin: self.bounds.origin, size: targetSize),
      from: CGRect.zero,
      operation: .sourceOver,
      fraction: 1,
      respectFlipped: true,
      hints: nil
    )
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
        self.ugrid.cells[row][columnRange]
          .groupedRanges(with: { _, cell in cell.attrId })
          .compactMap { range in
            let cells = self.ugrid.cells[row][range]

            guard let firstCell = cells.first,
                  let attrs = self.cellAttributesCollection.attributes(
                    of: firstCell.attrId
                  )
              else {
              // GH-666: FIXME: correct error handling
              logger.error("row: \(row), range: \(range): " +
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

  func updateFontMetaData(_ newFont: NSFont) {
    self.runDrawer.baseFont = newFont

    self.cellSize = FontUtils.cellSize(
      of: newFont, linespacing: self.linespacing
    )

    self.baselineOffset = self.cellSize.height - CTFontGetAscent(newFont)
    self.resizeNeoVimUi(to: self.bounds.size)
  }
}

private let emojiAttrs = [
  NSAttributedStringKey.font: NSFont(name: "AppleColorEmoji", size: 72)!
]

private let resizeTextAttrs = [
  NSAttributedStringKey.font: NSFont.systemFont(ofSize: 18),
  NSAttributedStringKey.foregroundColor: NSColor.darkGray
]

private let infoTextAttrs = [
  NSAttributedStringKey.font: NSFont.systemFont(ofSize: 16),
  NSAttributedStringKey.foregroundColor: NSColor.darkGray
]

private let colorSpace = NSColorSpace.sRGB
