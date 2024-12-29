/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

public final class ThreadSafeFifoCache<Key: Hashable, Value> {
  public init(count: Int) {
    self.count = count
    self.keyWriteIndex = 0
    self.keys = Array(repeating: nil, count: count)
    self.storage = Dictionary(minimumCapacity: count)
  }

  public func set(_ value: Value, forKey key: Key) {
    self.lock.lock()
    defer { self.lock.unlock() }
    
    if let keyToDel = self.keys[self.keyWriteIndex] { self.storage.removeValue(forKey: keyToDel) }

    self.keys[self.keyWriteIndex] = key
    self.storage[key] = value

    self.keyWriteIndex = (self.keyWriteIndex + 1) % self.count
  }

  public func valueForKey(_ key: Key) -> Value? {
    lock.lock()
    let value = self.storage[key]
    lock.unlock()
    
    return value
  }
  
  public func clear() {
    self.keys = Array(repeating: nil, count: count)
    self.storage.removeAll(keepingCapacity: true)
  }

  private let count: Int
  private var keys: [Key?]
  private var keyWriteIndex: Int
  private var storage: [Key: Value]
  
  private let lock = OSAllocatedUnfairLock()
}

public final class FifoCache<Key: Hashable, Value> {
  public init(count: Int) {
    self.count = count
    self.keyWriteIndex = 0
    self.keys = Array(repeating: nil, count: count)
    self.storage = Dictionary(minimumCapacity: count)
  }

  public func set(_ value: Value, forKey key: Key) {
    if let keyToDel = self.keys[self.keyWriteIndex] { self.storage.removeValue(forKey: keyToDel) }

    self.keys[self.keyWriteIndex] = key
    self.storage[key] = value

    self.keyWriteIndex = (self.keyWriteIndex + 1) % self.count
  }

  public func valueForKey(_ key: Key) -> Value? { self.storage[key] }
  
  public func clear() {
    self.keys = Array(repeating: nil, count: count)
    self.storage.removeAll(keepingCapacity: true)
  }

  private let count: Int
  private var keys: [Key?]
  private var keyWriteIndex: Int
  private var storage: [Key: Value]
}
