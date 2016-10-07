/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public class DispatchUtils {
  
  fileprivate static let qDispatchMainQueue = DispatchQueue.main
  
  public static func gui(_ call: @escaping () -> Void) {
    DispatchUtils.qDispatchMainQueue.async(execute: call)
  }
}
