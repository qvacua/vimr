/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class ShortcutItem: NSObject, Comparable {

  static func <(lhs: ShortcutItem, rhs: ShortcutItem) -> Bool { lhs.title < rhs.title }

  @objc dynamic var title: String
  @objc dynamic var isLeaf: Bool

  @objc dynamic var childrenCount: Int { self.children?.count ?? -1 }

  var identifier: String? { self.item?.identifier?.rawValue }

  var isContainer: Bool { !self.isLeaf }

  override var description: String {
    "<ShortcutItem: \(title), " +
    "id: '\(self.identifier ?? "")', " +
    "isLeaf: \(self.isLeaf), " +
    "childrenCount: \(self.children?.count ?? -1)" +
    ">"
  }

  let item: NSMenuItem?
  @objc dynamic var children: [ShortcutItem]?

  init(title: String, isLeaf: Bool, item: NSMenuItem?) {
    self.title = title
    self.isLeaf = isLeaf
    self.item = item
    self.children = isLeaf ? nil : []
  }
}
