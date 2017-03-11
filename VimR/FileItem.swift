/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Token: Hashable, CustomStringConvertible {

  var hashValue: Int {
    return ObjectIdentifier(self).hashValue
  }

  var description: String {
    return ObjectIdentifier(self).debugDescription
  }

  static func == (left: Token, right: Token) -> Bool {
    return left === right
  }
}

class FileItem : CustomStringConvertible, Hashable, Comparable, Copyable {

  typealias InstanceType = FileItem

  static func ==(left: FileItem, right: FileItem) -> Bool {
    return left.url == right.url
  }

  static func <(left: FileItem, right: FileItem) -> Bool {
    return left.url.lastPathComponent < right.url.lastPathComponent
  }

  let url: URL
  let isDir: Bool
  let isHidden: Bool
  let isPackage: Bool

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
      + "ignore=\(self.ignore), ignoreToken=\(self.ignoreToken), "
      + "children=\(self.children.count)>"
  }

  init(_ url: URL) {
    self.url = url
    self.isDir = url.isDir
    self.isHidden = url.isHidden
    self.isPackage = url.isPackage
  }

  fileprivate init(url: URL, dir: Bool, hidden: Bool, package: Bool) {
    self.url = url
    self.isDir = dir
    self.isHidden = hidden
    self.isPackage = package
  }

  func copy() -> FileItem {
    let item = FileItem(url: self.url, dir: self.isDir, hidden: self.isHidden, package: self.isPackage)
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

  func deepChild(with url: URL) -> FileItem? {
    let pathComps = self.url.pathComponents
    let childPathComps = url.pathComponents

    guard childPathComps.count > pathComps.count else {
      return nil
    }

    return childPathComps[pathComps.count..<childPathComps.count].reduce(self) { (result, pathComp) -> FileItem? in
      guard let parent = result else {
        return nil
      }

      return parent.child(with: parent.url.appendingPathComponent(pathComp))
    }
  }

  func remove(childWith url: URL) {
    guard let idx = self.children.index(where: { $0.url == url }) else {
      return
    }

    self.children.remove(at: idx)
  }
}
