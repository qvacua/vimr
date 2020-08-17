/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

extension CFRange {

  static let zero = CFRange(location: 0, length: 0)
}

extension CGSize {

  func scaling(_ factor: CGFloat) -> CGSize {
    return CGSize(width: self.width * factor, height: self.height * factor)
  }
}

extension CGRect {

  public var hashValue: Int {
    let o = Int(self.origin.x) << 10 ^ Int(self.origin.y)
    let s = Int(self.size.width) << 10 ^ Int(self.size.height)
    return o + s
  }
}

