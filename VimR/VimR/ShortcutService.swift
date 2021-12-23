/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import ShortcutRecorder

class ShortcutService {
  func update(shortcuts: [Shortcut]) {
    self.shortcuts = shortcuts
  }

  func isMenuItemShortcut(_ event: NSEvent) -> Bool {
    if let shortcut = Shortcut(event: event), self.shortcuts.contains(shortcut) { return true }

    return false
  }

  private var shortcuts = [Shortcut]()
}
