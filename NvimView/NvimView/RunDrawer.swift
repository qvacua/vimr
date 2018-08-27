/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class RunDrawer {

  private let logger = LogContext.stdoutLogger(
    as: String(reflecting: RunDrawer.self)
  )

  var baseFont: NSFont {
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

  init(baseFont: NSFont, linespacing: CGFloat, usesLigatures: Bool) {
    self.baseFont = baseFont
    self.linespacing = linespacing
    self.usesLigatures = usesLigatures

    self.updateFontMetrics()
  }

  func draw(_ run: Run.Attributes, `in` context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    self.draw(backgroundFor: run, in: context)

    let font = FontUtils.font(adding: run.attrs.fontTrait, to: self.baseFont)

    context.setFillColor(
      ColorUtils.cgColorIgnoringAlpha(run.attrs.effectiveForeground)
    )

    if usesLigatures {
      self.typesetter.fontGlyphRunsWithLigatures(
          nvimUtf16Cells: run.cells.map { Array($0.string.utf16) },
          startColumn: run.cells.startIndex,
          yPosition: run.location.y + self.baselineOffset,
          foreground: run.attrs.effectiveForeground,
          font: font,
          cellWidth: self.cellSize.width
        )
        .forEach { $0.draw(in: context) }
    } else {
      self.typesetter.fontGlyphRunsWithoutLigatures(
          nvimCells: run.cells.map { $0.string },
          startColumn: run.cells.startIndex,
          yPosition: run.location.y + self.baselineOffset,
          foreground: run.attrs.effectiveForeground,
          font: font,
          cellWidth: self.cellSize.width
        )
        .forEach { $0.draw(in: context) }
    }

    // TODO: GH-666: Draw underline/curl
  }

  private let typesetter = Typesetter()

  var cellSize: CGSize = .zero
  private var baselineOffset: CGFloat = 0
  private var underlinePosition: CGFloat = 0
  private var underlineThickness: CGFloat = 0

  private func draw(
    backgroundFor run: Run.Attributes, `in` context: CGContext
  ) {
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

  private func updateFontMetrics() {
    self.cellSize = FontUtils.cellSize(of: baseFont, linespacing: linespacing)
    self.baselineOffset = self.cellSize.height - CTFontGetAscent(self.baseFont)
    self.underlinePosition = CTFontGetUnderlinePosition(baseFont)
    self.underlineThickness = CTFontGetUnderlineThickness(baseFont)
  }
}
