/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public extension NvimView {
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    self.isFile(sender: sender) ? .copy : NSDragOperation()
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    self.isFile(sender: sender) ? .copy : NSDragOperation()
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    guard self.isFile(sender: sender) else { return false }

    guard let urls = sender.draggingPasteboard
      .readObjects(forClasses: [NSURL.self]) as? [URL] else { return false }

    Task { await self.open(urls: urls) }
    return true
  }

  private func isFile(sender: NSDraggingInfo) -> Bool {
    (sender.draggingPasteboard.types?.contains(NSPasteboard.PasteboardType.fileURL)) ?? false
  }
}
