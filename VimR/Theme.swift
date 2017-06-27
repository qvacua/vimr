/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import SwiftNeoVim

struct Theme: CustomStringConvertible {

  static let `default` = Theme()

  var foreground = NSColor.textColor
  var background = NSColor.textBackgroundColor

  var highlightForeground = NSColor.selectedMenuItemTextColor
  var highlightBackground = NSColor.selectedMenuItemColor

  public var description: String {
    return "Theme<" +
           "fg: \(self.foreground.hex), bg: \(self.background.hex), " +
           "hl-fg: \(self.highlightForeground.hex), hl-bg: \(self.highlightBackground.hex)" +
           ">"
  }

  init() {

  }

  init(_ neoVimTheme: NeoVimView.Theme) {
    self.foreground = neoVimTheme.foreground
    self.background = neoVimTheme.background

    self.highlightForeground = neoVimTheme.visualForeground
    self.highlightBackground = neoVimTheme.visualBackground
  }
}
