/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public extension CFRange {
  static let zero = CFRange(location: 0, length: 0)
}

public extension CGSize {
  func scaling(_ factor: CGFloat) -> CGSize {
    CGSize(width: self.width * factor, height: self.height * factor)
  }
}

public extension CGRect {
  var hashValue: Int {
    let o = Int(self.origin.x) << 10 ^ Int(self.origin.y)
    let s = Int(self.size.width) << 10 ^ Int(self.size.height)
    return o + s
  }
}
