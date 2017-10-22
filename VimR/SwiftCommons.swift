/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

func identity<T>(_ input: T) -> T {
  return input
}

extension String {

  func without(prefix: String) -> String {
    guard self.hasPrefix(prefix) else {
      return self
    }

    let idx = self.index(self.startIndex, offsetBy: prefix.characters.count)
    return String(self[idx..<self.endIndex])
  }
}

extension Array {

  /// Concurrent and chunked version of `Array.map`.
  ///
  /// - parameters:
  ///   - chunk: Batch size; defaults to `100`.
  ///   - queue: Defaults to `dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)`.
  ///   - transform: The transform function.
  /// - returns: Transformed array of `self`.
  func concurrentChunkMap<R>(
    _ chunk: Int = 100,
    queue: DispatchQueue = .global(qos: .userInitiated),
    transform: (Element) -> R
  ) -> [R] {
    let count = self.count

    let chunkedCount = Int(ceil(Float(count) / Float(chunk)))
    var result: [[R]] = []

    var spinLock = OS_SPINLOCK_INIT

    DispatchQueue.concurrentPerform(iterations: chunkedCount) { idx in
      let startIndex = Swift.min(idx * chunk, count)
      let endIndex = Swift.min(startIndex + chunk, count)

      let mappedChunk = self[startIndex..<endIndex].map(transform)

      OSSpinLockLock(&spinLock)
      result.append(mappedChunk)
      OSSpinLockUnlock(&spinLock)
    }

    return result.flatMap { $0 }
  }
}

extension Array where Element: Equatable {

  func removingDuplicatesPreservingFromBeginning() -> [Element] {
    var result = [Element]()

    for value in self {
      if result.contains(value) == false {
        result.append(value)
      }
    }

    return result
  }

  /**
   Returns an array where elements of `elements` contained in the array are substituted by elements of `elements`.
   This is useful when you need pointer equality rather than `Equatable`-equality like in `NSOutlineView`.

   If an element of `elements` is not contained in the array, it's ignored.
   */
  func substituting(elements: [Element]) -> [Element] {
    let elementsInArray = elements.filter { self.contains($0) }
    let indices = elementsInArray.flatMap { self.index(of: $0) }

    var result = self
    indices.enumerated().forEach { result[$0.1] = elementsInArray[$0.0] }

    return result
  }
}

extension Array where Element: Hashable {

  func toDict<V>(by mapper: @escaping (Element) -> V) -> Dictionary<Element, V> {
    var result = Dictionary<Element, V>(minimumCapacity: self.count)
    self.forEach { result[$0] = mapper($0) }

    return result
  }
}

func tuplesToDict<K:Hashable, V, S:Sequence>(_ sequence: S) -> Dictionary<K, V> where S.Iterator.Element == (K, V) {
  var result = Dictionary<K, V>(minimumCapacity: sequence.underestimatedCount)

  for (key, value) in sequence {
    result[key] = value
  }

  return result
}

extension Dictionary {

  func mapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)) rethrows -> Dictionary<K, V> {
    let array = try self.map(transform)
    return tuplesToDict(array)
  }

  func flatMapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)?) rethrows -> Dictionary<K, V> {
    let array = try self.flatMap(transform)
    return tuplesToDict(array)
  }
}
