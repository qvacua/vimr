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

struct Theme: CustomStringConvertible, Sendable {
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
  var cssLinkColor = NSColor(hex: "0366d6")!
  var cssHrColor = NSColor(hex: "dfe2e5")!
  var cssBlockquoteBorderColor = NSColor(hex: "dfe2e5")!
  var cssBlockquoteColor = NSColor(hex: "6a737d")!
  var cssH2BorderColor = NSColor(hex: "eaecef")!
  var cssH6Color = NSColor(hex: "6a737d")!
  var cssCodeColor = NSColor(hex: "24292e")!
  var cssCodeBackgroundColor = NSColor(hex: "1b1f23")!

  var cssCommentColor = NSColor.darkGray
  var cssStringColor = NSColor.brown
  var cssBooleanColor = NSColor.purple
  var cssNumberColor = NSColor.blue
  var cssStatementColor = NSColor.systemTeal
  var cssTypeColor = NSColor.systemGreen
  var cssConstantColor = NSColor.systemRed
  var cssSpecialColor = NSColor.systemOrange

  var description: String {
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

    self.cssColor = nvimTheme.foreground
    self.cssBackgroundColor = nvimTheme.background
    self.cssHrColor = nvimTheme.foreground.withAlphaComponent(0.2)
    self.cssBlockquoteBorderColor = nvimTheme.foreground.withAlphaComponent(0.4)
    self.cssH2BorderColor = nvimTheme.foreground.withAlphaComponent(0.2)
    self.cssH6Color = nvimTheme.foreground.withAlphaComponent(0.7)

    self.updateCssColors(additionalColorDict)
  }

  private mutating func updateCssColors(_ colors: [String: CellAttributes]) {
    if let directory = colors["Directory"] {
      self.cssLinkColor = NSColor(rgb: directory.effectiveForeground)
    }

    if let question = colors["Question"] {
      self.cssBlockquoteColor = NSColor(rgb: question.effectiveForeground)
    }

    if let cursorColumn = colors["CursorColumn"] {
      self.cssCodeColor = NSColor(rgb: cursorColumn.effectiveForeground)
      self.cssCodeBackgroundColor = NSColor(rgb: cursorColumn.effectiveBackground)
    }

    if let comment = colors["Comment"] {
      self.cssCommentColor = NSColor(rgb: comment.effectiveForeground)
    }

    if let string = colors["String"] {
      self.cssStringColor = NSColor(rgb: string.effectiveForeground)
    }

    if let boolean = colors["Boolean"] {
      self.cssBooleanColor = NSColor(rgb: boolean.effectiveForeground)
    }

    if let number = colors["Number"] {
      self.cssNumberColor = NSColor(rgb: number.effectiveForeground)
    }

    if let statement = colors["Statement"] {
      self.cssStatementColor = NSColor(rgb: statement.effectiveForeground)
    }

    if let type = colors["Type"] {
      self.cssTypeColor = NSColor(rgb: type.effectiveForeground)
    }

    if let constant = colors["Constant"] {
      self.cssConstantColor = NSColor(rgb: constant.effectiveForeground)
    }

    if let special = colors["Special"] {
      self.cssSpecialColor = NSColor(rgb: special.effectiveForeground)
    }
  }
}
