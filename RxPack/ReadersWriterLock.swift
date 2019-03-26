/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Darwin

class ReadersWriterLock {

  private let rwlock
    = UnsafeMutablePointer<pthread_rwlock_t>.allocate(capacity: 1)

  init() {
    pthread_rwlock_init(rwlock, nil)
  }

  deinit {
    pthread_rwlock_destroy(rwlock)
    self.rwlock.deallocate()
  }

  func readLock() {
    pthread_rwlock_rdlock(self.rwlock)
  }

  func readUnlock() {
    pthread_rwlock_unlock(self.rwlock)
  }

  func writeLock() {
    pthread_rwlock_wrlock(self.rwlock)
  }

  func writeUnlock() {
    pthread_rwlock_unlock(self.rwlock)
  }

  @discardableResult
  func withReadLock<T>(_ body: () -> T) -> T {
    self.readLock()
    defer { self.readUnlock() }
    return body()
  }

  @discardableResult
  func withWriteLock<T>(_ body: () -> T) -> T {
    self.writeLock()
    defer { self.writeUnlock() }
    return body()
  }
}
