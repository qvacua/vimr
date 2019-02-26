/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class ShortcutItem: NSObject, Comparable {

  static func <(lhs: ShortcutItem, rhs: ShortcutItem) -> Bool {
    return lhs.title < rhs.title
  }

  @objc dynamic var title: String
  @objc dynamic var isLeaf: Bool

  @objc dynamic var childrenCount: Int {
    return self.children?.count ?? -1
  }

  var isContainer: Bool {
    return !self.isLeaf
  }

  override var description: String {
    return "<ShortcutItem: \(title), " +
           "id: '\(self.item?.identifier?.rawValue ?? "")', " +
           "isLeaf: \(self.isLeaf), " +
           "childrenCount: \(self.children?.count ?? -1)" +
           ">"
  }

  let item: NSMenuItem?
  @objc dynamic var children: [ShortcutItem]?

  init(
    title: String,
    isLeaf: Bool,
    item: NSMenuItem?
  ) {
    self.title = title
    self.isLeaf = isLeaf
    self.item = item
    self.children = isLeaf ? nil : []
  }
}
