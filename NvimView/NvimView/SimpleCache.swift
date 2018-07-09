/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */


import Foundation

class SimpleCache<K: Hashable, V> {

  private class ValueBox<T> {

    fileprivate let value: T

    fileprivate init(_ value: T) {
      self.value = value
    }
  }

  private class KeyBox<K: Hashable>: NSObject {

    fileprivate let key: K

    fileprivate init(_ key: K) {
      self.key = key
    }

    override var hash: Int {
      return key.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
      return self.key == (object as? KeyBox<K>)?.key
    }
  }

  private let cache = NSCache<KeyBox<K>, ValueBox<V>>()

  init(countLimit: Int? = nil) {
    if let limit = countLimit {
      self.cache.countLimit = limit
    }
  }

  func object(forKey key: K) -> V? {
    return self.cache.object(forKey: KeyBox(key))?.value
  }

  func set(object: V, forKey key: K) {
    self.cache.setObject(ValueBox(object), forKey: KeyBox(key))
  }

  func removeObject(forKey key: K) {
    cache.removeObject(forKey: KeyBox(key))
  }

  func removeAllObjects() {
    cache.removeAllObjects()
  }
}
