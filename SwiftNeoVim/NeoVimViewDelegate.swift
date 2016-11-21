/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

// See http://stackoverflow.com/a/24104371 for class
public protocol NeoVimViewDelegate: class {

  func neoVimStopped()
  func set(title: String)
  func set(dirtyStatus: Bool)
  func cwdChanged()
  func bufferListChanged()
}
