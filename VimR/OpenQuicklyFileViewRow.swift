/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class OpenQuicklyFileViewRow: NSTableRowView {

  override func drawSelectionInRect(dirtyRect: NSRect) {
    if self.selected {
      NSColor.selectedControlColor().set()
    } else {
      NSColor.clearColor().set()
    }

    self.rectsBeingDrawn().forEach { NSRectFillUsingOperation(NSIntersectionRect($0, dirtyRect), .CompositeSourceOver) }
  }

  private func rectsBeingDrawn() -> [CGRect] {
    var rectsPtr: UnsafePointer<CGRect> = nil
    var count: Int = 0
    self.getRectsBeingDrawn(&rectsPtr, count: &count)

    return Array(UnsafeBufferPointer(start: rectsPtr, count: count))
  }
}
