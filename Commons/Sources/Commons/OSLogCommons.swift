/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

public extension OSLog {
  func trace(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    #if TRACE
      self.log(
        type: .debug,
        msg: "%{public}@",
        "[\((file as NSString).lastPathComponent) - \(function):\(line)] [TRACE] \(msg)"
      )
    #endif
  }

  func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    #if DEBUG
      self.log(
        type: .debug,
        msg: "%{public}@",
        "[\((file as NSString).lastPathComponent) - \(function):\(line)]"
      )
    #endif
  }

  func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    #if DEBUG
      self.log(
        type: .debug,
        msg: "%{public}@",
        "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
      )
    #endif
  }

  func info(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    self.log(
      type: .info,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  func `default`(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    self.log(
      type: .default,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  func error(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    self.log(
      type: .error,
      msg: "%{public}@",
      "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    )
  }

  func fault(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
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
