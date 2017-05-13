/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileItem : CustomStringConvertible, Hashable, Comparable, Copyable {

  typealias InstanceType = FileItem

  static func ==(left: FileItem, right: FileItem) -> Bool {
    return left.url == right.url
  }

  static func <(left: FileItem, right: FileItem) -> Bool {
    return left.url.lastPathComponent < right.url.lastPathComponent
  }

  let url: URL

  var isDir: Bool {
    return self.url.isDir
  }

  var isHidden: Bool {
    return self.url.isHidden
  }

  var isPackage: Bool {
    return self.isPackage
  }

  var hashValue: Int {
    return url.hashValue
  }

  /// When nil, then it has never been fnmatch'ed.
  weak var ignoreToken: Token?
  var ignore = false

  var needsScanChildren = false
  var childrenScanned = false

  var children: [FileItem] = []

  var description: String {
    return "<FileItem: \(self.url), dir=\(self.isDir), hidden=\(self.isHidden), package=\(self.isPackage), "
      + "needsScan=\(self.needsScanChildren), childrenScanned=\(self.childrenScanned), "
      + "ignore=\(self.ignore), ignoreToken=\(String(describing: self.ignoreToken)), "
      + "children=\(self.children.count)>"
  }

  init(_ url: URL) {
    self.url = url
  }

  func copy() -> FileItem {
    let item = FileItem(self.url)
    item.needsScanChildren = self.needsScanChildren
    item.childrenScanned = self.childrenScanned
    item.children = self.children

    return item
  }

  func child(with url: URL) -> FileItem? {
    guard let idx = self.children.index(where: { $0.url == url }) else {
      return nil
    }

    return self.children[idx]
  }
}
