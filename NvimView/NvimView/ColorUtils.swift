/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

private let colorCache = SimpleCache<Int, NSColor>(countLimit: 200)
private let cgColorCache = SimpleCache<Int, CGColor>(countLimit: 200)

class ColorUtils {

  /// ARGB
  static func cgColorIgnoringAlpha(_ rgb: Int) -> CGColor {
    if let color = cgColorCache.object(forKey: rgb) {
      return color
    }

    let color = self.colorIgnoringAlpha(rgb).cgColor
    cgColorCache.set(object: color, forKey: rgb)

    return color
  }

  static func cgColorIgnoringAlpha(_ rgb: Int32) -> CGColor {
    if let color = cgColorCache.object(forKey: Int(rgb)) {
      return color
    }

    let color = self.colorIgnoringAlpha(Int(rgb)).cgColor
    cgColorCache.set(object: color, forKey: Int(rgb))

    return color
  }

  /// ARGB
  static func colorIgnoringAlpha(_ rgb: Int) -> NSColor {
    if let color = colorCache.object(forKey: rgb) {
      return color
    }

    // @formatter:off
    let red =   (CGFloat((rgb >> 16) & 0xFF)) / 255.0;
    let green = (CGFloat((rgb >>  8) & 0xFF)) / 255.0;
    let blue =  (CGFloat((rgb      ) & 0xFF)) / 255.0;
    // @formatter:on

    let color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    colorCache.set(object: color, forKey: rgb)

    return color
  }
}
