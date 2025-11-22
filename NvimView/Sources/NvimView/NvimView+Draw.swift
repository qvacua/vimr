/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import os

extension NvimView {
  override public func viewDidMoveToWindow() { self.window?.colorSpace = colorSpace }

  override public func draw(_: NSRect) {
    let signpostID = signposter.makeSignpostID()
    let state = signposter.beginInterval("draw", id: signpostID)
    defer { signposter.endInterval("draw", state) }

    guard self.ugrid.hasData else { return }

    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    defer { context.restoreGState() }

    if self.isCurrentlyPinching {
      signposter.emitEvent("drawPinchImage", id: signpostID)
      self.drawPinchImage(in: context)
      return
    }

    // See chapter 11 from "Programming with Quartz".
    switch self.fontSmoothing {
    case .noAntiAliasing:
      context.setShouldAntialias(false)
      context.setShouldSmoothFonts(false)
    case .noFontSmoothing:
      context.setShouldAntialias(true)
      context.setShouldSmoothFonts(false)
    case .withFontSmoothing:
      context.setShouldAntialias(true)
      context.setShouldSmoothFonts(true)
    case .systemSetting:
      break
    }
    context.setTextDrawingMode(.fill)

    let dirtyRects = self.rectsBeingDrawn()

    let backgroundState = signposter.beginInterval("drawBackground", id: signpostID)
    self.draw(defaultBackgroundIn: dirtyRects, in: context)
    signposter.endInterval("drawBackground", backgroundState)

    let cellsState = signposter.beginInterval("drawCells", id: signpostID)
    self.draw(cellsIntersectingRects: dirtyRects, in: context)
    signposter.endInterval("drawCells", cellsState)

    let cursorState = signposter.beginInterval("drawCursor", id: signpostID)
    self.draw(cursorIn: context)
    signposter.endInterval("drawCursor", cursorState)

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
    defaultBackgroundIn dirtyRects: [CGRect], in context: CGContext
  ) {
    context.setFillColor(
      ColorUtils.cgColorIgnoringAlpha(self.cellAttributesCollection.defaultAttributes.background)
    )
    context.fill(dirtyRects)
  }

  private func draw(cursorIn context: CGContext) {
    let cursorPosition = self.ugrid.cursorPositionWithMarkedInfo()
    let defaultAttrs = self.cellAttributesCollection.defaultAttributes

    let cursorRegion = self.cursorRegion(for: cursorPosition)
    if cursorRegion.top < 0
      || cursorRegion.bottom > self.ugrid.size.height - 1
      || cursorRegion.left < 0
      || cursorRegion.right > self.ugrid.size.width - 1
    {
      self.logger.error("\(cursorRegion) vs. \(self.ugrid.size)")
      return
    }
    guard let cellAtCursorAttrs = self.cellAttributesCollection.attributes(
      of: self.ugrid.cells[cursorPosition.row][cursorPosition.column].attrId
    ) else {
      self.logger.error("Could not get the attributes at cursor: \(cursorPosition)")
      return
    }

    guard let modeInfo = modeInfos[self.mode.rawValue] else {
      self.logger.error("Could not get modeInfo for mode index \(self.mode.rawValue)")
      return
    }

    guard let cursorAttrId = modeInfo.attrId,
          let cursorShapeAttrs = self.cellAttributesCollection.attributes(
            of: cursorAttrId,
            withDefaults: cellAtCursorAttrs
          )
    else {
      self.logger.error("Could not get the attributes for cursor in mode: \(mode) \(modeInfo)")
      return
    }

    // will be used for clipping
    var cursorRect: CGRect
    let cursorTextColor: Int

    switch modeInfo.cursorShape {
    case .block:
      cursorRect = self.rect(for: cursorRegion)
      cursorTextColor = cursorShapeAttrs.effectiveForeground
    case let .horizontal(cellPercentage):
      cursorRect = self.rect(for: cursorRegion)
      cursorRect.size.height = (cursorRect.size.height * CGFloat(cellPercentage)) / 100
      cursorTextColor = cellAtCursorAttrs.effectiveForeground
    case let .vertical(cellPercentage):
      cursorRect = self.rect(forRow: cursorPosition.row, column: cursorPosition.column)
      cursorRect.size.width = (cursorRect.size.width * CGFloat(cellPercentage)) / 100
      cursorTextColor = cellAtCursorAttrs.effectiveForeground
    }

    let cursorAttrs = CellAttributes(
      fontTrait: cellAtCursorAttrs.fontTrait,
      foreground: cursorTextColor,
      background: cursorShapeAttrs.effectiveBackground,
      special: cellAtCursorAttrs.special,
      reverse: !cellAtCursorAttrs.reverse
    )

    context.saveGState()
    // clip to cursor rect to support shapes like "ver25" and "hor50"
    context.clip(to: cursorRect)
    let attrsRun = AttributesRun(
      location: self.pointInView(forRow: cursorPosition.row, column: cursorPosition.column),
      cells: self.ugrid.cells[cursorPosition.row][cursorRegion.columnRange],
      attrs: cursorAttrs
    )
    self.drawer.draw([attrsRun], defaultAttributes: defaultAttrs, offset: self.offset, in: context)
    context.restoreGState()
  }

  private func drawPinchImage(in context: CGContext) {
    context.interpolationQuality = .none

    let boundsSize = self.bounds.size
    let targetSize = CGSize(
      width: boundsSize.width * self.pinchTargetScale,
      height: boundsSize.height * self.pinchTargetScale
    )
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
    rects.flatMap { rect in
      let region = self.region(for: rect)
      return self.runs(forRowRange: region.rowRange, columnRange: region.columnRange)
    }
  }

  private func runs(
    forRowRange rowRange: ClosedRange<Int>,
    columnRange: ClosedRange<Int>
  ) -> [AttributesRun] {
    var result = [AttributesRun]()
    // Estimate the capacity, median value from scrolling through a big Swift file
    result.reserveCapacity(rowRange.count * 3)

    // We use for-loops instead of flatMap and compactMap because, normal for-loops seem to be
    // faster. Average duration of the function using signpost in Instruments indicates 45% win.
    for row in rowRange {
      let ranges = groupedRanges(of: self.ugrid.cells[row][columnRange])
      
      for range in ranges {
        guard let attrs = self.cellAttributesCollection.attributes(
          of: self.ugrid.cells[row][range.lowerBound].attrId
        ) else {
          self.logger.error(
            "row: \(row), range: \(range): Could not get CellAttributes with ID " +
              "\(self.ugrid.cells[row][range.lowerBound].attrId)"
          )
          continue
        }

        result.append(AttributesRun(
          location: self.pointInView(forRow: row, column: range.lowerBound),
          cells: self.ugrid.cells[row][range],
          attrs: attrs
        ))
      }
    }

    return result
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

private let colorSpace = NSColorSpace.sRGB

// Signpost for performance measurements
private let signpostLog = OSLog(
  subsystem: "com.qvacua.VimR.NvimView",
  category: .pointsOfInterest
)
private let signposter = OSSignposter(logHandle: signpostLog)

/// When we use the following private function instead of the public extension function in
/// Commons.FoundationCommons.swift.groupedRanges(with:), then, according to Instruments
/// the percentage of the function is reduced from ~ 15% to 0%.
/// Keep the logic in sync with Commons.FoundationCommons.swift.groupedRanges(with:). Tests are
/// present in Commons lib.
private func groupedRanges(of cells: ArraySlice<UCell>) -> [ClosedRange<Int>] {
  if cells.isEmpty { return [] }

  var result = [ClosedRange<Int>]()
  result.reserveCapacity(cells.count / 2)

  var startIndex = cells.startIndex
  var lastMarker = cells[startIndex].attrId

  for i in cells.indices.dropFirst() {
    let currentMarker = cells[i].attrId
    if currentMarker != lastMarker {
      result.append(startIndex...(i - 1))
      startIndex = i
      lastMarker = currentMarker
    }
  }
  result.append(startIndex...(cells.endIndex - 1))

  return result
}
