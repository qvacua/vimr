/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import NvimView

func changeTheme(
  themePrefChanged: Bool,
  themeChanged: Bool,
  usesTheme: Bool,
  forTheme: () -> Void,
  forDefaultTheme: () -> Void
) -> Bool {
  if themePrefChanged, usesTheme {
    forTheme()
    return true
  }

  if themePrefChanged, !usesTheme {
    forDefaultTheme()
    return true
  }

  if !themePrefChanged, themeChanged, usesTheme {
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
  // NSColor.selectedMenuItemColor is deprecated. The doc says that
  // NSVisualEffectView.Material.selection should be used instead, but I don't know how to get
  // an NSColor from it.
  var highlightBackground = NSColor.selectedContentBackgroundColor

  var directoryForeground = NSColor.textColor

  var tabForeground = NSColor.selectedMenuItemTextColor
  var tabBackground = NSColor.selectedContentBackgroundColor

  var tabBarForeground = NSColor.selectedMenuItemTextColor
  var tabBarBackground = NSColor.selectedContentBackgroundColor

  var selectedTabForeground = NSColor.selectedMenuItemTextColor
  var selectedTabBackground = NSColor.selectedContentBackgroundColor

  var cssColor = NSColor(hex: "24292e")!
  var cssBackgroundColor = NSColor.white
  var cssA = NSColor(hex: "0366d6")!
  var cssHrBorderBackgroundColor = NSColor(hex: "dfe2e5")!
  var cssHrBorderBottomColor = NSColor(hex: "eeeeee")!
  var cssBlockquoteBorderLeftColor = NSColor(hex: "dfe2e5")!
  var cssBlockquoteColor = NSColor(hex: "6a737d")!
  var cssH2BorderBottomColor = NSColor(hex: "eaecef")!
  var cssH6Color = NSColor(hex: "6a737d")!
  var cssCodeColor = NSColor(hex: "24292e")!
  var cssCodeBackgroundColor = NSColor(hex: "1b1f23")!

  public var description: String {
    "Theme<" +
      "fg: \(self.foreground.hex), bg: \(self.background.hex), " +
      "hl-fg: \(self.highlightForeground.hex), hl-bg: \(self.highlightBackground.hex), " +
      "dir-fg: \(self.directoryForeground.hex), " +
      "tab-fg: \(self.tabForeground.hex), tab-bg: \(self.tabBackground.hex), " +
      "tabfill-fg: \(self.tabBarForeground.hex), tabfill-bg: \(self.tabBarBackground.hex), " +
      "tabsel-bg: \(self.selectedTabBackground.hex), tabsel-fg: \(self.selectedTabForeground.hex)" +
      ">"
  }

  init() {}

  init(from nvimTheme: NvimView.Theme, additionalColorDict: [String: CellAttributes]) {
    self.foreground = nvimTheme.foreground
    self.background = nvimTheme.background

    self.highlightForeground = nvimTheme.visualForeground
    self.highlightBackground = nvimTheme.visualBackground

    self.directoryForeground = nvimTheme.directoryForeground

    self.tabBackground = nvimTheme.tabBackground
    self.tabForeground = nvimTheme.tabForeground

    self.tabBarBackground = nvimTheme.tabBarBackground
    self.tabBarForeground = nvimTheme.tabBarForeground

    self.selectedTabBackground = nvimTheme.selectedTabBackground
    self.selectedTabForeground = nvimTheme.selectedTabForeground

    self.updateCssColors(additionalColorDict)
  }

  private mutating func updateCssColors(_ colors: [String: CellAttributes]) {
    guard let normal = colors["Normal"],
          let directory = colors["Directory"],
          let question = colors["Question"],
          let cursorColumn = colors["CursorColumn"] else { return }

    self.cssColor = NSColor(rgb: normal.effectiveForeground)
    self.cssBackgroundColor = NSColor(rgb: normal.effectiveBackground)
    self.cssA = NSColor(rgb: directory.effectiveForeground)
    self.cssHrBorderBackgroundColor = NSColor(rgb: cursorColumn.effectiveForeground)
    self.cssHrBorderBottomColor = NSColor(rgb: cursorColumn.effectiveBackground)
    self.cssBlockquoteBorderLeftColor = NSColor(rgb: cursorColumn.effectiveForeground)
    self.cssBlockquoteColor = NSColor(rgb: question.effectiveBackground)
    self.cssH2BorderBottomColor = NSColor(rgb: cursorColumn.effectiveBackground)
    self.cssH6Color = NSColor(rgb: normal.effectiveForeground)
    self.cssCodeColor = NSColor(rgb: cursorColumn.effectiveForeground)
    self.cssCodeBackgroundColor = NSColor(rgb: cursorColumn.effectiveBackground)
  }
}
