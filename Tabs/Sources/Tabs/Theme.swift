/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MaterialIcons

public struct Theme {
  public static let `default` = Self()

  public var separatorColor = NSColor.gridColor
  public var backgroundColor = NSColor.textBackgroundColor
  public var foregroundColor = NSColor.textColor {
    didSet {
      self.closeButtonImage = Icon.close.asImage(
        dimension: self.iconDimension.width,
        color: self.foregroundColor
      )
    }
  }
	
  public var selectedBackgroundColor = NSColor.selectedTextBackgroundColor
  public var selectedForegroundColor = NSColor.selectedTextColor {
    didSet {
      self.selectedCloseButtonImage = Icon.close.asImage(
        dimension: self.iconDimension.width,
        color: self.selectedForegroundColor
      )
    }
  }
  public var tabSelectedIndicatorColor = NSColor.selectedTextColor

  public var tabBarBackgroundColor = NSColor.windowBackgroundColor
  public var tabBarForegroundColor = NSColor.textColor
	
  public var titleFont = NSFont.systemFont(ofSize: 11)
  public var selectedTitleFont = NSFont.boldSystemFont(ofSize: 11)

  public var tabHeight = CGFloat(28)

  public var tabMaxWidth = CGFloat(250)
  public var separatorThickness = CGFloat(1)
  public var tabHorizontalPadding = CGFloat(4)
  public var tabSelectionIndicatorThickness = CGFloat(3)
  public var iconDimension = CGSize(width: 16, height: 16)

  public var tabMinWidth: CGFloat {
    3 * self.tabHorizontalPadding + self.iconDimension.width + 32
  }

  public var tabBarHeight: CGFloat { self.tabHeight }
  public var tabSpacing = CGFloat(-1)

  public var closeButtonImage: NSImage
  public var selectedCloseButtonImage: NSImage

  public init() {
    self.closeButtonImage = Icon.close.asImage(
      dimension: self.iconDimension.width,
      color: self.foregroundColor
    )
    self.selectedCloseButtonImage = Icon.close.asImage(
      dimension: self.iconDimension.width,
      color: self.foregroundColor
    )
  }
}
