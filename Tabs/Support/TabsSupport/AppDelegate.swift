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
    self.tabBar = TabBar(withTheme: .default)
    super.init()
  }

  func applicationDidFinishLaunching(_: Notification) {
    let contentView = self.window.contentView!
    contentView.addSubview(self.tabBar)
    self.tabBar.autoPinEdge(toSuperviewEdge: .top)
    self.tabBar.autoPinEdge(toSuperviewEdge: .left)
    self.tabBar.autoPinEdge(toSuperviewEdge: .right)
    self.tabBar.autoSetDimension(.height, toSize: Theme().tabBarHeight)
    self.tabBar.selectHandler = { _, entry in Swift.print("selected \(entry)") }

    self.tabBar.update(tabRepresentatives: [
      DummyTabEntry(title: "Test 1"),
      DummyTabEntry(title: "Test 2"),
      DummyTabEntry(title: "Test 3"),
      DummyTabEntry(title: "Very long long long title, and some more text!"),
    ])
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  private let tabBar: TabBar<DummyTabEntry>
}

struct DummyTabEntry: Hashable, TabRepresentative {
  var title: String
  var isSelected = false
}
