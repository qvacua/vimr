/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import WebKit

struct Defs {

  static let loggerSubsystem = Bundle.main.bundleIdentifier!

  struct LoggerCategory {

    static let general = "general"

    static let ui = "ui"
    static let middleware = "middleware"
    static let service = "service"
  }

  static let webViewProcessPool = WKProcessPool()
}
