/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

// See http://stackoverflow.com/a/24104371 for class
public protocol NeoVimViewDelegate: class {
  
  func setTitle(title: String)
  func setDirtyStatus(dirty: Bool)
  func neoVimReady()
  func neoVimStopped()
}
