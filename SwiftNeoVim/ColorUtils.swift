/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class ColorUtils {

  static func colorFromCode(rgb: UInt32) -> NSColor {
    let red = (CGFloat((rgb >> 16) & 0x000000FF)) / 255.0;
    let green = (CGFloat((rgb >> 8 ) & 0x000000FF)) / 255.0;
    let blue = (CGFloat(rgb & 0x000000FF)) / 255.0;

    return NSColor(SRGBRed: red, green: green, blue: blue, alpha: 1.0)
  }
}
