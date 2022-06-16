/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import Ignore
import OrderedCollections

class IgnoreService {
  var root: URL {
    didSet {
      self.rootIgnore = Ignore(
        base: self.root,
        parent: Ignore.globalGitignoreCollection(base: self.root)
      )
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

    self.rootIgnore = Ignore(
      base: root,
      parent: Ignore.globalGitignoreCollection(base: root)
    )
  }

  func ignoreCollection(forUrl url: URL) -> Ignore? {
    self.queue.sync {
      if self.root == url { return self.rootIgnore }
      guard self.root.isAncestor(of: url) else { return nil }

      if url == self.root { return self.rootIgnore }
      if let ignore = self.storage[url] { return ignore }

      if let parentIgnore = self.storage[url.parent] {
        let ignore = Ignore(base: url, parent: parentIgnore)
        self.storage[url] = ignore

        return ignore
      }

      // Since we descend the directory structure step by step, the ignore of the parent should
      // already be present. Most probably we won't land here...
      let rootPathComp = self.root.pathComponents
      let pathComp = url.pathComponents.dropLast()
      let lineage = pathComp.suffix(from: rootPathComp.count)
      var ancestorUrl = self.root
      var ancestorIc = self.rootIgnore
      for ancestorComponent in lineage {
        ancestorUrl = ancestorUrl.appendingPathComponent(ancestorComponent, isDirectory: true)
        if self.storage[ancestorUrl] == nil {
          guard let ignore = Ignore(base: ancestorUrl, parent: ancestorIc) else {
            return nil
          }
          self.set(ignoreCollection: ignore, forUrl: url)
          ancestorIc = ignore
        }
      }

      return ancestorIc
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
