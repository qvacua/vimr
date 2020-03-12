/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

private struct SizedFontTrait: Hashable {

  static func ==(lhs: SizedFontTrait, rhs: SizedFontTrait) -> Bool {
    if lhs.trait != rhs.trait { return false }
    if lhs.size != rhs.size { return false }

    return true
  }

  fileprivate var trait: FontTrait
  fileprivate var size: CGFloat
}

extension FontTrait: Hashable {
}

final class FontUtils {

  static func cellSize(of font: NSFont, linespacing: CGFloat, characterspacing: CGFloat) -> CGSize {
    if let cached = cellSizeWithDefaultLinespacingCache.valueForKey(font) {
      return CGSize(
        width: characterspacing * cached.width,
        height: ceil(linespacing * cached.height)
      )
    }

    let capitalM = [UniChar(0x004D)]
    var glyph = [CGGlyph(0)]
    var advancement = CGSize.zero
    CTFontGetGlyphsForCharacters(font, capitalM, &glyph, 1)
    CTFontGetAdvancesForGlyphs(font, .horizontal, glyph, &advancement, 1)

    let ascent = CTFontGetAscent(font)
    let descent = CTFontGetDescent(font)
    let leading = CTFontGetLeading(font)

    let cellSizeToCache = CGSize(width: advancement.width, height: ceil(ascent + descent + leading))
    cellSizeWithDefaultLinespacingCache.set(cellSizeToCache, forKey: font)

    let cellSize = CGSize(
      width: characterspacing * advancement.width,
      height: ceil(linespacing * cellSizeToCache.height)
    )

    return cellSize
  }

  static func font(adding trait: FontTrait, to font: NSFont) -> NSFont {
    if trait.isEmpty { return font }

    let sizedFontTrait = SizedFontTrait(trait: trait, size: font.pointSize)

    if let cachedFont = fontCache.valueForKey(sizedFontTrait) { return cachedFont }

    var ctFontTrait: CTFontSymbolicTraits = []
    if trait.contains(.bold) { ctFontTrait.insert(.boldTrait) }

    if trait.contains(.italic) { ctFontTrait.insert(.italicTrait) }

    guard let ctFont = CTFontCreateCopyWithSymbolicTraits(
      font, 0.0, nil, ctFontTrait, ctFontTrait
    ) else {
      return font
    }

    fontCache.set(ctFont, forKey: sizedFontTrait)
    return ctFont
  }
}

private let fontCache = FifoCache<SizedFontTrait, NSFont>(count: 100)
private let cellSizeWithDefaultLinespacingCache = FifoCache<NSFont, CGSize>(count: 100)
