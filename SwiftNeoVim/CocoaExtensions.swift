/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension CGRect {

  func fill() {
    NSRectFill(self)
  }
}

extension NSRange: CustomStringConvertible {

  public var description: String {
    var location = ""
    if self.location == NSNotFound {
      location = "NotFound"
    } else {
      location = String(self.location)
    }
    return "NSRange<\(location), \(self.length)>"
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
