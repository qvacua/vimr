/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NvimView {

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

    guard let paths = sender.draggingPasteboard.propertyList(
      forType: NSPasteboard.PasteboardType(String(kUTTypeFileURL))
    ) as? [String] else {
      return false
    }

    self.open(urls: paths.map { URL(fileURLWithPath: $0) })
      .subscribeOn(self.scheduler)
      .trigger(onError: { error in
        self.eventsSubject.onNext(.apiError(msg: "\(paths) could not be opened.", cause: error))
      })

    return true
  }
}

private func isFile(sender: NSDraggingInfo) -> Bool {
  return (sender.draggingPasteboard.types?.contains(NSPasteboard.PasteboardType(String(kUTTypeFileURL)))) ?? false
}
