//
//  AppDelegate.swift
//  TabsSupport
//
//  Created by Tae Won Ha on 22.11.20.
//

import Cocoa
import PureLayout
import Tabs

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var window: NSWindow!

  override init() {
    self.tabBar = TabBar()
    super.init()
  }

  func applicationDidFinishLaunching(_: Notification) {
    let contentView = self.window.contentView!
    contentView.addSubview(self.tabBar)
    self.tabBar.autoPinEdge(toSuperviewEdge: .top)
    self.tabBar.autoPinEdge(toSuperviewEdge: .left)
    self.tabBar.autoPinEdge(toSuperviewEdge: .right)
    self.tabBar.autoSetDimension(.height, toSize: Defs.tabBarHeight)
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  private let tabBar: TabBar
}
