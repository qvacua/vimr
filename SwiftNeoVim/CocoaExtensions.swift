/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

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

extension CGRect {

  public var hashValue: Int {
    let o = Int(self.origin.x) << 10 ^ Int(self.origin.y)
    let s = Int(self.size.width) << 10 ^ Int(self.size.height)
    return o + s
  }
}

extension CGSize {

  func scaling(_ factor: CGFloat) -> CGSize {
    return CGSize(width: self.width * factor, height: self.height * factor)
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
