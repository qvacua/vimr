/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

final class OpenQuicklyFileViewRow: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    if self.isSelected {
      NSColor.selectedControlColor.set()
    } else {
      NSColor.clear.set()
    }

    self.rectsBeingDrawn().forEach {
      $0.intersection(dirtyRect).fill(using: .sourceOver)
    }
  }
}
