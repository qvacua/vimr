/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import Foundation

enum Defs {
  static let loggerSubsystem = Bundle.main.bundleIdentifier!

  enum LoggerCategory {
    static let general = "general"

    static let redux = "redux"
    static let ui = "ui"
    static let middleware = "middleware"
    static let service = "service"
  }
}

let dlog = DevLogger.shared
