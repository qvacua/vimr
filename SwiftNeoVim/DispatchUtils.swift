/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

open class DispatchUtils {
  
  fileprivate static let qDispatchMainQueue = DispatchQueue.main
  
  open static func gui(_ call: @escaping () -> Void) {
    DispatchUtils.qDispatchMainQueue.async(execute: call)
  }
}
