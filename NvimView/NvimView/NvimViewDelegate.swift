/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public enum NvimViewEvent {

  case neoVimStopped
  case setTitle(String)
  case setDirtyStatus(Bool)
  case cwdChanged
  case bufferListChanged
  case tabChanged
  
  case newCurrentBuffer(NvimView.Buffer)
  case bufferWritten(NvimView.Buffer)

  case colorschemeChanged(NvimView.Theme)

  case ipcBecameInvalid(String)

  case scroll
  case cursor(Position)
}
