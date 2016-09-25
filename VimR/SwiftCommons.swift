/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

func call(_ closure: @autoclosure () -> Void, when condition: Bool) { if condition { closure() } }
func call(_ closure: @autoclosure () -> Void, whenNot condition: Bool) { if !condition { closure() } }

extension String {

  func without(prefix: String) -> String {
    guard self.hasPrefix(prefix) else {
      return self
    }
    
    let idx = self.characters.index(self.startIndex, offsetBy: prefix.characters.count)
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
    _ chunk: Int = 100,
    queue: DispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated),
    transform: (Element) -> R) -> [R]
  {
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
