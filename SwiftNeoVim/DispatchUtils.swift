/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public class DispatchUtils {
  
  private static let qDispatchMainQueue = dispatch_get_main_queue()
  
  public static func gui(call: () -> Void) {
    dispatch_async(DispatchUtils.qDispatchMainQueue, call)
  }
}
