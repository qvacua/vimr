//
// Created by Tae Won Ha on 19.08.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Cocoa

protocol DrawableRun {

  var location: CGPoint { get }

  func draw(`in` context: CGContext)
}

protocol CustomFontDrawableRun: DrawableRun {

  var font: NSFont { get }
}

extension CFRange {

  static let zero = CFRange(location: 0, length: 0)
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

enum Run {

  struct Attributes {

    var location: CGPoint
    var cells: ArraySlice<UCell>
    let attrs: CellAttributes
  }

  struct CoreText: CustomFontDrawableRun {

    var location: CGPoint
    var ctRun: CTRun

    var utf16Positions: [CGPoint?]
    var glyphs: [CGGlyph]
    var advances: [CGSize]

    init(location: CGPoint, utf16Positions: [CGPoint?], ctRun: CTRun) {
      self.location = location
      self.ctRun = ctRun
      self.utf16Positions = utf16Positions

      let glyphCount = CTRunGetGlyphCount(ctRun)

      self.glyphs = Array(
        repeating: CGGlyph(), count: glyphCount
      )
      CTRunGetGlyphs(ctRun, .zero, &self.glyphs)

      self.advances = Array(
        repeating: .zero, count: glyphCount
      )
      CTRunGetAdvances(ctRun, .zero, &self.advances)

      var positions = Array<CGPoint>(
        repeating: .zero, count: glyphCount
      )
      CTRunGetPositions(ctRun, .zero, &positions)

      var indices = Array(
        repeating: CFIndex(), count: glyphCount
      )
      CTRunGetStringIndices(ctRun, .zero, &indices)

      print("font: \(self.font)")
      print("glyphs: \(glyphs)")
      print("utf16 pos: \(utf16Positions)")
      print("advances: \(advances)")
      print("positions: \(positions)")
      print("str indices: \(indices)")
    }

    var font: NSFont {
      guard let attrs =
      CTRunGetAttributes(self.ctRun) as? [NSAttributedStringKey: Any],
            let font = attrs[NSAttributedStringKey.font] as? NSFont else {

        // FIXME: GH-666: Return the default font
        preconditionFailure("ERROR!")
      }

      return font
    }

    func draw(`in` context: CGContext) {
      let ctRun = self.ctRun

      context.textMatrix = CGAffineTransform(translationX: self.location.x - self.xPosition(of: ctRun),
                                             y: self.location.y)
      CTRunDraw(ctRun, context, CFRange(location: 0, length: 0))
      context.textMatrix = CGAffineTransform.identity
    }

    private func xPosition(of ctRun: CTRun) -> CGFloat {
      if let posPtr = CTRunGetPositionsPtr(ctRun) {
        return posPtr.pointee.x
      }

      var pos = CGPoint.zero
      CTRunGetPositions(ctRun, .zero, &pos)
      return pos.x
    }
  }

  struct Glyphs: CustomFontDrawableRun {

    var location: CGPoint
    var glyphs: [CGGlyph]
    var font: NSFont
    var cellWidth: CGFloat

    func draw(`in` context: CGContext) {
      let positions = (0...self.glyphs.count).map {
        CGPoint(x: CGFloat($0) * self.cellWidth + self.location.x, y: self.location.y)
      }

      CTFontDrawGlyphs(self.font, self.glyphs, positions, self.glyphs.count, context)
    }
  }
}

private let typesetter = Typesetter()
