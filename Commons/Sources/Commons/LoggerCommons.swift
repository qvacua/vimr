/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

public extension Logger {
  func trace(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    #if TRACE
      let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] [TRACE] \(msg)"
      self.log(level: .debug, "\(message)")
    #endif
  }

  func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    #if DEBUG
      let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)]"
      self.log(level: .debug, "\(message)")
    #endif
  }

  func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    #if DEBUG
      let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
      self.log(level: .debug, "\(message)")
    #endif
  }

  func info(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    self.log(level: .info, "\(message)")
  }

  func error(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    self.log(level: .error, "\(message)")
  }

  func fault(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: some Any
  ) {
    let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
    self.log(level: .fault, "\(message)")
  }
}
