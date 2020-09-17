/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public final class FifoCache<Key: Hashable, Value> {

  public init(count: Int) {
    self.count = count
    self.keyWriteIndex = 0
    self.keys = Array(repeating: nil, count: count)
    self.storage = Dictionary(minimumCapacity: count)
  }

  public func set(_ value: Value, forKey key: Key) {
    self.queue.sync {
      self.keyWriteIndex = (self.keyWriteIndex + 1) % self.count

      if let keyToDel = self.keys[self.keyWriteIndex] { self.storage.removeValue(forKey: keyToDel) }

      self.keys[self.keyWriteIndex] = key
      self.storage[key] = value
    }
  }

  public func valueForKey(_ key: Key) -> Value? { self.queue.sync { self.storage[key] } }

  private let count: Int
  private var keys: Array<Key?>
  private var keyWriteIndex: Int
  private var storage: Dictionary<Key, Value>

  private let queue = DispatchQueue(label: "FifoCache-\(UUID().uuidString)", qos: .userInteractive)
}
