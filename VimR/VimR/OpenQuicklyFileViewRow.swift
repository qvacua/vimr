/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class OpenQuicklyFileViewRow: NSTableRowView {

  override func drawSelection(in dirtyRect: NSRect) {
    if self.isSelected {
      NSColor.selectedControlColor.set()
    } else {
      NSColor.clear.set()
    }

    self.rectsBeingDrawn().forEach { NSIntersectionRect($0, dirtyRect).fill(using: .sourceOver) }
  }
}
