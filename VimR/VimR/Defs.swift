/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import WebKit

struct Defs {

  static let loggerSubsystem = "com.qvacua.VimR"

  struct LoggerCategory {

    static let general = "general"

    static let uiComponents = "ui-components"
    static let middleware = "middleware"
    static let service = "service"
  }

  static let webViewProcessPool = WKProcessPool()
}
