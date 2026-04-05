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

  case revealCurrentBufferInFileBrowser =
    "com.qvacua.vimr.rpc-events.reveal-current-buffer-in-file-browser"
  case refreshFileBrowser = "com.qvacua.vimr.rpc-events.refresh-file-browser"

  /// Open a new blank VimR window with VimR's own nvim process.
  case openNewWindow = "com.qvacua.vimr.rpc-events.open-new-window"

  /// Open a new VimR window connected to an already-running neovim at the given address.
  /// Pass the socket path or host:port as the first RPC argument.
  case connectToRemote = "com.qvacua.vimr.rpc-events.connect-to-remote"
}
