/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public extension NvimView {
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    isFile(sender: sender) ? .copy : NSDragOperation()
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    isFile(sender: sender) ? .copy : NSDragOperation()
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    guard isFile(sender: sender) else { return false }

    guard let urls = sender.draggingPasteboard
      .readObjects(forClasses: [NSURL.self]) as? [URL] else { return false }

    self.open(urls: urls)
      .subscribe(on: self.scheduler)
      .subscribe(onError: { [weak self] error in
        self?.eventsSubject.onNext(
          .apiError(msg: "\(urls) could not be opened.", cause: error)
        )
      })
      .disposed(by: self.disposeBag)

    return true
  }
}

private func isFile(sender: NSDraggingInfo) -> Bool {
  (sender.draggingPasteboard.types?.contains(
    NSPasteboard.PasteboardType(String(kUTTypeFileURL))
  )) ?? false
}
