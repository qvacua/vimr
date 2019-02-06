/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

final class AttributesRunDrawer {

  var font: NSFont {
    didSet {
      self.updateFontMetrics()
    }
  }

  var linespacing: CGFloat {
    didSet {
      self.updateFontMetrics()
    }
  }

  var usesLigatures: Bool
  private(set) var cellSize: CGSize = .zero
  private(set) var baselineOffset: CGFloat = 0
  private(set) var underlinePosition: CGFloat = 0
  private(set) var underlineThickness: CGFloat = 0

  init(baseFont: NSFont, linespacing: CGFloat, usesLigatures: Bool) {
    self.font = baseFont
    self.linespacing = linespacing
    self.usesLigatures = usesLigatures

    self.updateFontMetrics()
  }

  func draw(
    _ attrsRuns: [AttributesRun],
    defaultAttributes: CellAttributes,
    offset: CGPoint,
    `in` context: CGContext
  ) {
#if DEBUG
    self.drawByParallelComputation(
      attrsRuns,
      defaultAttributes: defaultAttributes,
      offset: offset,
      in: context
    )
#else
    let runs = attrsRuns.map { self.fontGlyphRuns(from: $0, offset: offset) }

    for i in 0..<attrsRuns.count {
      self.draw(
        attrsRuns[i],
        fontGlyphRuns: runs[i],
        defaultAttributes: defaultAttributes,
        in: context
      )
    }
#endif
  }

  private func draw(
    _ run: AttributesRun,
    fontGlyphRuns: [FontGlyphRun],
    defaultAttributes: CellAttributes,
    `in` context: CGContext
  ) {
    context.saveGState()
    defer { context.restoreGState() }

    self.draw(
      backgroundFor: run,
      with: defaultAttributes,
      in: context
    )

    context.setFillColor(
      ColorUtils.cgColorIgnoringAlpha(run.attrs.effectiveForeground)
    )

    fontGlyphRuns.forEach { run in
      CTFontDrawGlyphs(
        run.font,
        run.glyphs,
        run.positions,
        run.glyphs.count,
        context
      )
    }

    // TODO: GH-666: Draw underline/curl
  }

  private let typesetter = Typesetter()

  private func draw(
    backgroundFor run: AttributesRun,
    with defaultAttributes: CellAttributes,
    `in` context: CGContext
  ) {

    if run.attrs.effectiveBackground == defaultAttributes.background { return }

    context.saveGState()
    defer { context.restoreGState() }

    let cellCount = CGFloat(run.cells.endIndex - run.cells.startIndex)
    let backgroundRect = CGRect(
      x: run.location.x,
      y: run.location.y,
      width: cellCount * self.cellSize.width,
      height: self.cellSize.height
    )

    context.setFillColor(
      ColorUtils.cgColorIgnoringAlpha(run.attrs.effectiveBackground)
    )
    context.fill(backgroundRect)
  }

  private func fontGlyphRuns(
    from attrsRun: AttributesRun,
    offset: CGPoint
  ) -> [FontGlyphRun] {
    let font = FontUtils.font(
      adding: attrsRun.attrs.fontTrait, to: self.font
    )

    let typesetFunction = self.usesLigatures
      ? self.typesetter.fontGlyphRunsWithLigatures
      : self.typesetter.fontGlyphRunsWithoutLigatures

    let fontGlyphRuns = typesetFunction(
      attrsRun.cells.map { Array($0.string.utf16) },
      attrsRun.cells.startIndex,
      CGPoint(
        x: offset.x, y: attrsRun.location.y + self.baselineOffset
      ),
      font,
      self.cellSize.width
    )

    return fontGlyphRuns
  }

  private func drawByParallelComputation(
    _ attrsRuns: [AttributesRun],
    defaultAttributes: CellAttributes,
    offset: CGPoint,
    `in` context: CGContext
  ) {
    var result = Array(repeating: [FontGlyphRun](), count: attrsRuns.count)
    DispatchQueue.concurrentPerform(iterations: attrsRuns.count) { i in
      result[i] = self.fontGlyphRuns(from: attrsRuns[i], offset: offset)
    }

    attrsRuns.enumerated().forEach { (i, attrsRun) in
      self.draw(
        attrsRun,
        fontGlyphRuns: result[i],
        defaultAttributes: defaultAttributes,
        in: context
      )
    }
  }

  private func updateFontMetrics() {
    self.cellSize = FontUtils.cellSize(
      of: self.font, linespacing: linespacing
    )
    self.baselineOffset = self.cellSize.height - CTFontGetAscent(self.font)
    self.underlinePosition = CTFontGetUnderlinePosition(font)
    self.underlineThickness = CTFontGetUnderlineThickness(font)
  }
}
