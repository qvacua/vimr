/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

final class ColorUtils {

  /// ARGB
  static func cgColorIgnoringAlpha(_ rgb: Int) -> CGColor {
    if let color = cgColorCache.valueForKey(rgb) { return color }

    let color = self.colorIgnoringAlpha(rgb).cgColor
    cgColorCache.set(color, forKey: rgb)

    return color
  }

  static func cgColorIgnoringAlpha(_ rgb: Int32) -> CGColor {
    if let color = cgColorCache.valueForKey(Int(rgb)) { return color }

    let color = self.colorIgnoringAlpha(Int(rgb)).cgColor
    cgColorCache.set(color, forKey: Int(rgb))

    return color
  }

  /// ARGB
  static func colorIgnoringAlpha(_ rgb: Int) -> NSColor {
    if let color = colorCache.valueForKey(rgb) { return color }

    // @formatter:off
    let red =   ((rgb >> 16) & 0xFF).cgf / 255.0;
    let green = ((rgb >>  8) & 0xFF).cgf / 255.0;
    let blue =  ((rgb      ) & 0xFF).cgf / 255.0;
    // @formatter:on

    let color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    colorCache.set(color, forKey: rgb)

    return color
  }
}

private let colorCache = FifoCache<Int, NSColor>(count: 500)
private let cgColorCache = FifoCache<Int, CGColor>(count: 500)
