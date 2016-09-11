/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

func call(@autoclosure closure: () -> Void, when condition: Bool) { if condition { closure() } }
func call(@autoclosure closure: () -> Void, whenNot condition: Bool) { if !condition { closure() } }

extension String {

  func without(prefix prefix: String) -> String {
    guard self.hasPrefix(prefix) else {
      return self
    }
    
    let idx = self.startIndex.advancedBy(prefix.characters.count)
    return self[idx..<self.endIndex]
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
    chunk: Int = 100,
    queue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),
    transform: (Element) -> R) -> [R]
  {
    let count = self.count
    
    let chunkedCount = Int(ceil(Float(count) / Float(chunk)))
    var result: [[R]] = []

    var spinLock = OS_SPINLOCK_INIT

    dispatch_apply(chunkedCount, queue) { idx in
      let startIndex = min(idx * chunk, count)
      let endIndex = min(startIndex + chunk, count)

      let mappedChunk = self[startIndex..<endIndex].map(transform)

      OSSpinLockLock(&spinLock)
      result.append(mappedChunk)
      OSSpinLockUnlock(&spinLock)
    }
    
    return result.flatMap { $0 }
  }
}