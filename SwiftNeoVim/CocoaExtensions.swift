/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension CGRect {

  public var hashValue: Int {
    return Int(self.origin.x) << 10 ^ Int(self.origin.y) +
           Int(self.size.width) << 10 ^ Int(self.size.height);
  }
}

extension CGSize {

  func scaling(_ factor: CGFloat) -> CGSize {
    return CGSize(width: self.width * factor, height: self.height * factor)
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
