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
    self.draw(cellsIntersectingRects: dirtyRects, in: context)
    self.draw(cursorIn: context)

    #if DEBUG
//    self.draw(cellGridIn: context)
    #endif
  }

  private func draw(
    cellsIntersectingRects dirtyRects: [CGRect], in context: CGContext
  ) {
    self.drawer.draw(
      self.runs(intersecting: dirtyRects),
      defaultAttributes: self.cellAttributesCollection.defaultAttributes,
      offset: self.offset,
      in: context
    )
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

  private func draw(cursorIn context: CGContext) {
    // The position stays at the first cell when we enter the terminal mode
    // and the cursor seems to be drawn by changing the background color of
    // the corresponding cell...
    if self.mode == .termFocus { return }

    let cursorPosition = self.ugrid.cursorPosition
    let defaultAttrs = self.cellAttributesCollection.defaultAttributes

    let cursorRegion = self.cursorRegion(for: self.ugrid.cursorPosition)
    if cursorRegion.top < 0
       || cursorRegion.bottom > self.ugrid.size.height - 1
       || cursorRegion.left < 0
       || cursorRegion.right > self.ugrid.size.width - 1 {
      self.log.error("\(cursorRegion) vs. \(self.ugrid.size)")
      return
    }
    guard let cellAtCursorAttrs = self.cellAttributesCollection.attributes(
      of: self.ugrid.cells[cursorPosition.row][cursorPosition.column].attrId
    ) else {
      self.log.error("Could not get the attributes" +
                     " at cursor: \(cursorPosition)")
      return
    }

    guard self.modeInfoList.count > self.mode.rawValue else {
      self.log.error("Could not get modeInfo for mode index \(self.mode.rawValue)")
      return
    }
    let modeInfo = modeInfoList[Int(mode.rawValue)]

    guard let cursorAttrId = modeInfo.attrId,
      let cursorShapeAttrs = self.cellAttributesCollection.attributes(
        of: cursorAttrId,
        withDefaults: cellAtCursorAttrs
      ) else {
        self.log.error("Could not get the attributes" +
          " for cursor in mode: \(mode) \(modeInfo)")
        return
    }

    // will be used for clipping
    var cursorRect: CGRect
    var cursorTextColor: Int

    switch (modeInfo.cursorShape) {
    case .Block:
      cursorRect = self.rect(for: cursorRegion)
      cursorTextColor = cursorShapeAttrs.effectiveForeground
    case .Horizontal(let cellPercentage):
      cursorRect = self.rect(for: cursorRegion)
      cursorRect.size.height = (cursorRect.size.height * CGFloat(cellPercentage)) / 100
      cursorTextColor = cellAtCursorAttrs.effectiveForeground
    case .Vertical(let cellPercentage):
      cursorRect = self.rect(forRow: cursorPosition.row, column: cursorPosition.column)
      cursorRect.size.width = (cursorRect.size.width * CGFloat(cellPercentage)) / 100
      cursorTextColor = cellAtCursorAttrs.effectiveForeground
    }

    let cursorAttrs = CellAttributes(
      fontTrait: cellAtCursorAttrs.fontTrait,
      foreground: cursorTextColor,
      background: cursorShapeAttrs.effectiveBackground,
      special: cellAtCursorAttrs.special,
      reverse: false)

    context.saveGState()
    // clip to cursor rect to support shapes like "ver25" and "hor50"
    context.clip(to: cursorRect)
    let attrsRun = AttributesRun(
      location: self.pointInView(
        forRow: cursorPosition.row, column: cursorPosition.column
      ),
      cells: self.ugrid.cells[cursorPosition.row][cursorRegion.columnRange],
      attrs: cursorAttrs
    )
    self.drawer.draw(
      [attrsRun],
      defaultAttributes: defaultAttrs,
      offset: self.offset,
      in: context
    )
    context.restoreGState()
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
              self.log.error("row: \(row), range: \(range): " +
                             "Could not get CellAttributes with ID " +
                             "\(String(describing: cells.first?.attrId))")
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
    self.drawer.font = newFont
    self.drawer.linespacing = self.linespacing
    self.drawer.characterspacing = self.characterspacing

    self.cellSize = self.drawer.cellSize
    self.baselineOffset = self.drawer.baselineOffset

    self.resizeNeoVimUi(to: self.bounds.size)
  }
}

private let emojiAttrs = [
  NSAttributedString.Key.font: NSFont(name: "AppleColorEmoji", size: 72)!
]

private let resizeTextAttrs = [
  NSAttributedString.Key.font: NSFont.systemFont(ofSize: 18),
  NSAttributedString.Key.foregroundColor: NSColor.darkGray
]

private let infoTextAttrs = [
  NSAttributedString.Key.font: NSFont.systemFont(ofSize: 16),
  NSAttributedString.Key.foregroundColor: NSColor.darkGray
]

private let colorSpace = NSColorSpace.sRGB
