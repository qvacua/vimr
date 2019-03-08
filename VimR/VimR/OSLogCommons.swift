/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

extension OSLog {

  func trace<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: T
  ) {
    #if TRACE
    self.log(
      type: .debug,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] [TRACE]"
    )
    #endif
  }

  func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    self.log(
      type: .debug,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)]"
    )
  }

  func debug<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: T
  ) {
    #if DEBUG
    self.log(
      type: .debug,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
    #endif
  }

  func info<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: T
  ) {
    self.log(
      type: .info,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  func `default`<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: T
  ) {
    self.log(
      type: .default,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  func error<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: T
  ) {
    self.log(
      type: .error,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  func fault<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: T
  ) {
    self.log(
      type: .fault,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  private func log(
    type: OSLogType,
    msg: StaticString,
    _ object: CVarArg
  ) {
    os_log(msg, log: self, type: type, object)
  }
}
