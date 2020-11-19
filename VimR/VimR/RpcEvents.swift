/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

enum RpcEvent: String, CaseIterable {
  static let prefix = "com.qvacua.vimr.rpc-events"

  case makeSessionTemporary = "com.qvacua.vimr.rpc-events.make-session-temporary"
  case maximizeWindow = "com.qvacua.vimr.rpc-events.maximize-window"
  case toggleTools = "com.qvacua.vimr.rpc-events.toggle-tools"
  case toggleToolButtons = "com.qvacua.vimr.rpc-events.toggle-tool-buttons"
  case toggleFullScreen = "com.qvacua.vimr.rpc-events.toggle-fullscreen"

  case setFont = "com.qvacua.vimr.rpc-events.set-font"
  case setLinespacing = "com.qvacua.vimr.rpc-events.set-linespacing"
  case setCharacterspacing = "com.qvacua.vimr.rpc-events.set-characterspacing"
}
