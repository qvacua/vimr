//
//  AppDelegate.swift
//  OutlineViewTest
//
//  Created by Tae Won Ha on 25/11/2016.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

import Cocoa
import PureLayout

class Item {

  let name: String
  let children: [Item]

  init(_ children: [Item]) {
    self.name = Item.randomString(length: 75)
    self.children = children
  }

  static func randomString(length: Int) -> String {

    let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)

    var randomString = ""

    for _ in 0 ..< length {
      let rand = arc4random_uniform(len)
      var nextChar = letters.character(at: Int(rand))
      randomString += NSString(characters: &nextChar, length: 1) as String
    }

    return randomString + "-END"
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  let outlineView = NSOutlineView.standardOutlineView()
  let scrollView = NSScrollView.standardScrollView()

  let data = Item([
                      Item([
                               Item([]),
                               Item([
                                        Item([]), Item([]), Item([]),
                                    ]),
                           ]),
                      Item([
                               Item([]), Item([]), Item([]), Item([]),
                           ]),
                      Item([
                               Item([
                                        Item([]), Item([]), Item([]), Item([]),
                                    ]),

                               Item([
                                        Item([]), Item([]),
                                    ])

                           ]),
                      Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]), Item([]),
                  ])

  @IBAction func debug1(_ sender: Any?) {
    let item = self.data.children[2]
    outlineView.reloadItem(item, reloadChildren: true)
    NSLog("reloaded")
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    outlineView.dataSource = self
    outlineView.delegate = self
    outlineView.reloadData()

    scrollView.documentView = outlineView
    scrollView.borderType = .noBorder

    let view = self.window.contentView!
    view.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return data.children.count
    }

    guard let a = item as? Item else {
      return 0
    }

    return a.children.count
  }

  func adjustColumnWidth(for items: [Item], outlineViewLevel level: Int) {
    let cellWidth = items.reduce(CGFloat(0)) { (curMaxWidth, item) in
      let itemWidth = ImageAndTextTableCell.width(with: item.name)
      if itemWidth > curMaxWidth {
        return itemWidth
      }

      return curMaxWidth
    }

    let width = cellWidth + (CGFloat(level) * outlineView.indentationPerLevel)
    let column = self.outlineView.outlineTableColumn!
    guard column.minWidth < width else {
      return
    }

    column.minWidth = width
    column.maxWidth = width
  }

  func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    let level = outlineView.level(forItem: item) + 2

    if item == nil {
      self.adjustColumnWidth(for: data.children, outlineViewLevel: level)
      return data.children[index]
    }


    guard let a = item as? Item else {
      preconditionFailure("Should not happen")
    }

    self.adjustColumnWidth(for: a.children, outlineViewLevel: level)
    return a.children[index]
  }

  func outlineView(_: NSOutlineView, isItemExpandable item: Any) ->  Bool {
    return !(item as! Item).children.isEmpty
  }

  @objc(outlineView:objectValueForTableColumn:byItem:)
  func outlineView(_: NSOutlineView, objectValueFor: NSTableColumn?, byItem item: Any?) -> Any? {
    guard let a = item as? Item else {
      return nil
    }

    return a
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }

  @objc(outlineView:viewForTableColumn:item:)
  func outlineView(_ view: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    guard let a = item as? Item else {
      return nil
    }

    let cachedCell = view.make(withIdentifier: "row", owner: self)
    let cell = cachedCell as? ImageAndTextTableCell ?? ImageAndTextTableCell(withIdentifier: "row")

    cell.text = a.name

    return cell
  }

  func outlineView(_ outlineView: NSOutlineView,
                   didAdd rowView: NSTableRowView,
                   forRow row: Int)
  {
  }
}

