/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public enum Defs {
  public static let tabHeight = CGFloat(28)
  public static let tabMinWidth = CGFloat(100)
  public static let tabMaxWidth = CGFloat(400)
  public static let tabTitleFont = NSFont.systemFont(ofSize: 11)

  public static let tabPadding = CGFloat(0)
  
  public static let tabBarHeight = CGFloat(Self.tabHeight + 2 * Self.tabPadding)
}
