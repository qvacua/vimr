/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView {

  override public func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    return isFile(sender: sender) ? .copy : NSDragOperation()
  }

  override public func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    return isFile(sender: sender) ? .copy : NSDragOperation()
  }

  override public func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    guard isFile(sender: sender) else {
      return false
    }

    guard let paths = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? [String] else {
      return false
    }

    self.open(urls: paths.map { URL(fileURLWithPath: $0) })

    return true
  }
}

fileprivate func isFile(sender: NSDraggingInfo) -> Bool {
  return (sender.draggingPasteboard().types?.contains(String(kUTTypeFileURL))) ?? false
}
