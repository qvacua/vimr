/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

struct AttributesRun {

  var location: CGPoint
  var cells: ArraySlice<UCell>
  let attrs: CellAttributes
}

struct FontGlyphRun {

  var font: NSFont
  var glyphs: [CGGlyph]
  var positions: [CGPoint]

  func draw(`in` context: CGContext) {
    CTFontDrawGlyphs(
      self.font,
      self.glyphs,
      self.positions,
      self.glyphs.count,
      context
    )
  }
}
