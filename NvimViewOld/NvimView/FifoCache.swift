/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class FifoCache<Key: Hashable, Value> {

  init(count: Int) {
    self.count = count
    self.keyWriteIndex = 0
    self.keys = Array(repeating: nil, count: count)
    self.storage = Dictionary(minimumCapacity: count)
  }

  func set(_ value: Value, forKey key: Key) {
    self.lock.lock()
    defer { self.lock.unlock() }

    self.keyWriteIndex = (self.keyWriteIndex + 1) % self.count

    if let keyToDel = self.keys[self.keyWriteIndex] { self.storage.removeValue(forKey: keyToDel) }

    self.keys[self.keyWriteIndex] = key
    self.storage[key] = value
  }

  func valueForKey(_ key: Key) -> Value? { self.lock.withLock { self.storage[key] } }

  private let count: Int
  private var keys: Array<Key?>
  private var keyWriteIndex: Int
  private var storage: Dictionary<Key, Value>

  private let lock = Lock()
}

fileprivate final class Lock {

  init() { pthread_mutex_init(self.mutex, nil) }

  deinit {
    pthread_mutex_destroy(self.mutex)
    self.mutex.deallocate()
  }

  func lock() { pthread_mutex_lock(self.mutex) }

  func unlock() { pthread_mutex_unlock(self.mutex) }

  func withLock<T>(_ body: () -> T) -> T {
    self.lock()
    defer { self.unlock() }
    return body()
  }

  private let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
}
