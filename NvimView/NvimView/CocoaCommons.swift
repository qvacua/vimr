/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NSRange {

  static let notFound = NSRange(location: NSNotFound, length: 0)
}

extension NSColor {

  var hex: String {
    if let color = self.usingColorSpace(.sRGB) {
      return "#" +
             String(format: "%X", Int(color.redComponent * 255)) +
             String(format: "%X", Int(color.greenComponent * 255)) +
             String(format: "%X", Int(color.blueComponent * 255)) +
             String(format: "%X", Int(color.alphaComponent * 255))
    } else {
      return self.description
    }
  }
}

extension NSView {

  /// - Returns: Rects currently being drawn
  /// - Warning: Call only in drawRect()
  func rectsBeingDrawn() -> [CGRect] {
    var rectsPtr: UnsafePointer<CGRect>? = nil
    var count: Int = 0
    self.getRectsBeingDrawn(&rectsPtr, count: &count)

    return Array(UnsafeBufferPointer(start: rectsPtr, count: count))
  }
}

extension NSEvent.ModifierFlags {

  // Values are from https://github.com/SFML/SFML/blob/master/src/SFML/Window/OSX/SFKeyboardModifiersHelper.mm
  // @formatter:off
  static let rightShift   = NSEvent.ModifierFlags(rawValue: 0x020004)
  static let leftShift    = NSEvent.ModifierFlags(rawValue: 0x020002)
  static let rightCommand = NSEvent.ModifierFlags(rawValue: 0x100010)
  static let leftCommand  = NSEvent.ModifierFlags(rawValue: 0x100008)
  static let rightOption  = NSEvent.ModifierFlags(rawValue: 0x080040)
  static let leftOption   = NSEvent.ModifierFlags(rawValue: 0x080020)
  static let rightControl = NSEvent.ModifierFlags(rawValue: 0x042000)
  static let leftControl  = NSEvent.ModifierFlags(rawValue: 0x040001)
  // @formatter:on
}
