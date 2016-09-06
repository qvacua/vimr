/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

extension NSURL {
  
  /// Wrapper function for NSURL.getResourceValue for Bool values.
  /// Returns also `false` when
  /// - there is no value for the given `key` or
  /// - the value cannot be converted to `NSNumber`.
  ///
  /// - parameters:
  ///   - key: The `key`-parameter of `NSURL.getResourceValue`.
  func resourceValue(key: String) -> Bool {
    var rsrc: AnyObject?
    
    do {
      try self.getResourceValue(&rsrc, forKey: key)
    } catch {
      // FIXME error handling
      print("\(#function): \(self) -> ERROR while getting \(key)")
      return false
    }
    
    if let result = rsrc as? NSNumber {
      return result.boolValue
    }
    
    return false
  }

  var dir: Bool {
    return self.resourceValue(NSURLIsDirectoryKey)
  }

  var hidden: Bool {
    return self.resourceValue(NSURLIsHiddenKey)
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
