/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Commons
import Foundation
import Ignore
import OrderedCollections

class IgnoreService {
  var root: URL {
    didSet {
      self.rootIgnore = Ignore(base: self.root, parent: Ignore.globalGitignore(base: self.root))
    }
  }

  init(count: Int, root: URL) {
    self.root = root
    self.count = count
    self.queue = DispatchQueue(
      label: "\(String(reflecting: IgnoreService.self))-\(UUID().uuidString)",
      qos: .default,
      target: .global(qos: DispatchQoS.default.qosClass)
    )
    self.storage = OrderedDictionary(minimumCapacity: count)

    self.rootIgnore = Ignore(base: root, parent: Ignore.globalGitignore(base: root))
  }

  func ignore(for url: URL) -> Ignore? {
    self.queue.sync {
      if self.root == url { return self.rootIgnore }
      guard self.root.isAncestor(of: url) else { return nil }

      if let ignore = self.storage[url] { return ignore }

      if let parentIgnore = self.storage[url.parent] {
        let ignore = Ignore.parentOrIgnore(for: url, withParent: parentIgnore)
        self.storage[url] = ignore

        return ignore
      }

      // Since we descend the directory structure step by step, the ignore of the parent should
      // already be present. Most probably we won't land here...
      let rootPathComp = self.root.pathComponents
      let pathComp = url.pathComponents
      let lineage = pathComp.suffix(from: rootPathComp.count)
      var ancestorUrl = self.root
      var ancestorIgnore = self.rootIgnore
      for ancestorComponent in lineage {
        ancestorUrl = ancestorUrl.appendingPathComponent(ancestorComponent, isDirectory: true)
        if let cachedAncestorIc = self.storage[ancestorUrl] { ancestorIgnore = cachedAncestorIc }
        else {
          guard let ignore = Ignore.parentOrIgnore(
            for: ancestorUrl,
            withParent: ancestorIgnore
          ) else { return nil }

          self.set(ignoreCollection: ignore, forUrl: ancestorUrl)
          ancestorIgnore = ignore
        }
      }

      return ancestorIgnore
    }
  }

  private func set(ignoreCollection: Ignore, forUrl url: URL) {
    if self.storage.count == self.count { self.storage.removeFirst() }
    self.storage[url] = ignoreCollection
  }

  private var rootIgnore: Ignore?

  private let count: Int
  private var storage: OrderedDictionary<URL, Ignore>

  private let queue: DispatchQueue
}
