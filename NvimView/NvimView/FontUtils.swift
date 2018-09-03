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

  var hashValue: Int {
    return self.trait.hashValue ^ self.size.hashValue
  }

  fileprivate var trait: FontTrait
  fileprivate var size: CGFloat
}

extension FontTrait: Hashable {

  public var hashValue: Int {
    return Int(self.rawValue)
  }
}

final class FontUtils {

  static func cellSize(of font: NSFont, linespacing: CGFloat) -> CGSize {
    if let cached = cellSizeCache.object(forKey: font) {
      return cached
    }

    let capitalM = [UniChar(0x004D)]
    var glyph = [CGGlyph(0)]
    var advancement = CGSize.zero
    CTFontGetGlyphsForCharacters(font, capitalM, &glyph, 1)
    CTFontGetAdvancesForGlyphs(font, .horizontal, glyph, &advancement, 1)

    let ascent = CTFontGetAscent(font)
    let descent = CTFontGetDescent(font)
    let leading = CTFontGetLeading(font)

    let cellSize = CGSize(
      width: advancement.width,
      height: ceil(linespacing * (ascent + descent + leading))
    )
    cellSizeCache.set(object: cellSize, forKey: font)

    return cellSize
  }

  static func font(adding trait: FontTrait, to font: NSFont) -> NSFont {
    if trait.isEmpty {
      return font
    }

    let sizedFontTrait = SizedFontTrait(trait: trait, size: font.pointSize)

    if let cachedFont = fontCache.object(forKey: sizedFontTrait) {
      return cachedFont
    }

    var ctFontTrait: CTFontSymbolicTraits = []
    if trait.contains(.bold) {
      ctFontTrait.insert(.boldTrait)
    }

    if trait.contains(.italic) {
      ctFontTrait.insert(.italicTrait)
    }

    guard let ctFont = CTFontCreateCopyWithSymbolicTraits(font, 0.0, nil, ctFontTrait, ctFontTrait) else {
      return font
    }

    fontCache.set(object: ctFont, forKey: sizedFontTrait)
    return ctFont
  }
}

private let fontCache = SimpleCache<SizedFontTrait, NSFont>(countLimit: 100)
private let cellSizeCache = SimpleCache<NSFont, CGSize>(countLimit: 100)
