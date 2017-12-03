/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView

func changeTheme(themePrefChanged: Bool, themeChanged: Bool, usesTheme: Bool,
                 forTheme: () -> Void, forDefaultTheme: () -> Void) -> Bool {

  if themePrefChanged && usesTheme {
    forTheme()
    return true
  }

  if themePrefChanged && !usesTheme {
    forDefaultTheme()
    return true
  }

  if !themePrefChanged && themeChanged && usesTheme {
    forTheme()
    return true
  }

  return false
}

struct Theme: CustomStringConvertible {

  static let `default` = Theme()

  var foreground = NSColor.textColor
  var background = NSColor.textBackgroundColor

  var highlightForeground = NSColor.selectedMenuItemTextColor
  var highlightBackground = NSColor.selectedMenuItemColor

  var directoryForeground = NSColor.textColor

  public var description: String {
    return "Theme<" +
           "fg: \(self.foreground.hex), bg: \(self.background.hex), " +
           "hl-fg: \(self.highlightForeground.hex), hl-bg: \(self.highlightBackground.hex)" +
           "dir-fg: \(self.directoryForeground.hex)" +
           ">"
  }

  init() {

  }

  init(_ neoVimTheme: NeoVimView.Theme) {
    self.foreground = neoVimTheme.foreground
    self.background = neoVimTheme.background

    self.highlightForeground = neoVimTheme.visualForeground
    self.highlightBackground = neoVimTheme.visualBackground

    self.directoryForeground = neoVimTheme.directoryForeground
  }
}
