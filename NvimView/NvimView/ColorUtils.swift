/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

private let colorCache = SimpleCache<Int, NSColor>(countLimit: 200)
private let cgColorCache = SimpleCache<Int, CGColor>(countLimit: 200)

class ColorUtils {

  static func cgColorIgnoringAlpha(_ rgb: Int) -> CGColor {
    if let color = cgColorCache.object(forKey: rgb) {
      return color
    }

    let color = self.colorIgnoringAlpha(rgb).cgColor
    cgColorCache.set(object: color, forKey: rgb)

    return color
  }

  static func colorIgnoringAlpha(_ rgb: Int) -> NSColor {
    if let color = colorCache.object(forKey: rgb) {
      return color
    }

    // @formatter:off
    let red =   (CGFloat((rgb >> 16) & 0xFF)) / 255.0;
    let green = (CGFloat((rgb >>  8) & 0xFF)) / 255.0;
    let blue =  (CGFloat((rgb      ) & 0xFF)) / 255.0;
    // @formatter:on

    let color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    colorCache.set(object: color, forKey: rgb)

    return color
  }
}

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

