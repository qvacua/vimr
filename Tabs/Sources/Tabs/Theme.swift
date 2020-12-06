/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public struct Theme {
  public static let `default` = Self()

  public var foregroundColor = NSColor.textColor
  public var backgroundColor = NSColor.controlBackgroundColor
  public var separatorColor = NSColor.white // NSColor.controlShadowColor

  public var selectedForegroundColor = NSColor.textColor
  public var selectedBackgroundColor = NSColor.selectedControlColor

  public var tabSelectedIndicatorColor = NSColor.blue

  public var titleFont = NSFont.systemFont(ofSize: 11)

  public var tabHeight = CGFloat(28)

  public var tabMaxWidth = CGFloat(250)
  public var separatorThickness = CGFloat(1)
  public var tabHorizontalPadding = CGFloat(4)
  public var tabSelectionIndicatorThickness = CGFloat(4)
  public var iconDimension = CGSize(width: 16, height: 16)

  public var tabMinWidth: CGFloat {
    4 * self.tabHorizontalPadding + 2 * self.iconDimension.width + 32
  }

  public var tabBarHeight: CGFloat { self.tabHeight }
  public var tabSpacing = CGFloat(-1)

  public init() {}
}
