/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Token: Equatable {

  static func == (left: Token, right: Token) -> Bool {
    return left === right
  }
}

class FileItem : CustomStringConvertible, Hashable {

  static func ==(left: FileItem, right: FileItem) -> Bool {
    return left.url == right.url
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

  func removeChild(withUrl url: URL) {
    guard let idx = self.children.index(where: { $0.url == url }) else {
      return
    }

    self.children.remove(at: idx)
  }
}
