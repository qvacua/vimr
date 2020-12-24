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

    let tb = self.tabBar
    tb.autoPinEdge(toSuperviewEdge: .top)
    tb.autoPinEdge(toSuperviewEdge: .left)
    tb.autoPinEdge(toSuperviewEdge: .right)
    tb.autoSetDimension(.height, toSize: Theme().tabBarHeight)
    tb.selectHandler = { [weak self] _, selectedEntry, _ in
      self?.tabEntries.enumerated().forEach { index, entry in
        self?.tabEntries[index].isSelected = (entry == selectedEntry)
      }
      DispatchQueue.main.async {
        Swift.print("select: \(self!.tabEntries)")
        self?.tabBar.update(tabRepresentatives: self?.tabEntries ?? [])
      }
    }
    tb.reorderHandler = { [weak self] index, reorderedEntry, entries in
      self?.tabEntries = entries
      self?.tabEntries.enumerated().forEach { index, entry in
        self?.tabEntries[index].isSelected = (entry == reorderedEntry)
      }
      DispatchQueue.main.async {
        Swift.print("reorder: \(entries)")
        self?.tabBar.update(tabRepresentatives: self?.tabEntries ?? [])
      }
    }

    self.tabEntries = [
      DummyTabEntry(title: "Test 1"),
      DummyTabEntry(title: "Test 2"),
      DummyTabEntry(title: "Test 3"),
      DummyTabEntry(title: "Very long long long title, and some more text!"),
    ]
    self.tabEntries[0].isSelected = true
    self.tabBar.update(tabRepresentatives: self.tabEntries)
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  private let tabBar: TabBar<DummyTabEntry>
  private var tabEntries = [DummyTabEntry]()
}

struct DummyTabEntry: Hashable, TabRepresentative {
  var title: String
  var isSelected = false
}
