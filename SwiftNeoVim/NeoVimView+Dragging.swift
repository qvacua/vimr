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
    if !isFile(sender: sender) {
      return false;
    }
    let paths = sender
      .draggingPasteboard()
      .propertyList(forType: NSFilenamesPboardType)
      as? [String]
    let urls = paths?
      .map { URL(fileURLWithPath: $0) }
      ?? []
    self.open(urls: urls)
    return true;
  }

}

fileprivate func isFile(sender: NSDraggingInfo?) -> Bool {
  return (sender?.draggingPasteboard().types?.contains(String(kUTTypeFileURL))) ?? false
}
