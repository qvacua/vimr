/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension CGRect: Hashable {

  public var hashValue: Int {
    return Int(self.origin.x) << 10 ^ Int(self.origin.y) +
           Int(self.size.width) << 10 ^ Int(self.size.height);
  }

  public func resizing(dw: CGFloat, dh: CGFloat) -> CGRect {
    return CGRect(origin: self.origin,
                  size: CGSize(width: self.size.width + dw, height: self.size.height + dh))
  }

  func scaling(_ factor: CGFloat) -> CGRect {
    return CGRect(origin: self.origin.scaling(factor), size: self.size.scaling(factor))
  }
}

extension CGPoint {

  func scaling(_ factor: CGFloat) -> CGPoint {
    return CGPoint(x: self.x * factor, y: self.y * factor)
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
