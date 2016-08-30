//
//  CwlMutex.swift
//  CwlUtils
//
//  Created by Matt Gallagher on 2015/02/03.
//  Copyright © 2015 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

// Slightly modified by Tae Won Ha

import Foundation

/// A basic wrapper around the "NORMAL" and "RECURSIVE" pthread mutex types. This type is a "class" type to take advantage of the "deinit" method.
final class PThreadMutex {
  // Non-recursive "PTHREAD_MUTEX_NORMAL" and recursive "PTHREAD_MUTEX_RECURSIVE" mutex types.
  enum PThreadMutexType {
    case Normal
    case Recursive
  }

  /// Exposed as an "unsafe" public property so non-scoped patterns can be implemented, if required.
  private(set) var unsafeMutex = pthread_mutex_t()

  /// Default constructs as ".Normal" or ".Recursive" on request.
  init(type: PThreadMutexType = .Normal) {
    var attr = pthread_mutexattr_t()
    guard pthread_mutexattr_init(&attr) == 0 else {
      preconditionFailure()
    }
    switch type {
    case .Normal:
      pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
    case .Recursive:
      pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
    }
    guard pthread_mutex_init(&unsafeMutex, &attr) == 0 else {
      preconditionFailure()
    }
  }

  deinit {
    pthread_mutex_destroy(&unsafeMutex)
  }

  /* RECOMMENDATION: Don't use the `slowsync` function if you care about performance. Instead, copy this extension into your file and call it:

   extension PThreadMutex {
   private func sync<R>(@noescape f: () throws -> R) rethrows -> R {
   pthread_mutex_lock(&unsafeMutex)
   defer { pthread_mutex_unlock(&unsafeMutex) }
   return try f()
   }
   }

   */
  func sync<R>(@noescape f: () throws -> R) rethrows -> R {
    pthread_mutex_lock(&unsafeMutex)
    defer { pthread_mutex_unlock(&unsafeMutex) }
    return try f()
  }

  /* RECOMMENDATION: Don't use the `trySlowsync` function if you care about performance. Instead, copy this extension into your file and call it:

   extension PThreadMutex {
   private func trySync<R>(@noescape f: () throws -> R) rethrows -> R? {
   guard pthread_mutex_trylock(&unsafeMutex) == 0 else { return nil }
   defer { pthread_mutex_unlock(&unsafeMutex) }
   return try f()
   }
   }

   */
  func trySlowsync<R>(@noescape f: () throws -> R) rethrows -> R? {
    guard pthread_mutex_trylock(&unsafeMutex) == 0 else { return nil }
    defer { pthread_mutex_unlock(&unsafeMutex) }
    return try f()
  }
}

#if PERFORMANCE_TESTS

  /// A basic scoped mutex wrapper around a `dispatch_semaphore_t`.
  /// For maximum performance, it is recommended that you copy this entire type into the same compilation unit as your code that uses it to ensure inlining.
  public struct DispatchSemaphore {
    let s = dispatch_semaphore_create(1)
    public init() {}
    public func sync<R>(@noescape f: () throws -> R) rethrows -> R {
      _ = dispatch_semaphore_wait(s, DISPATCH_TIME_FOREVER)
      defer { _ = dispatch_semaphore_signal(s) }
      return try f()
    }
  }

  extension PThreadMutex {
    public func sync_2<T>(inout param: T, @noescape f: (inout T) throws -> Void) rethrows -> Void {
      pthread_mutex_lock(&unsafeMutex)
      defer { pthread_mutex_unlock(&unsafeMutex) }
      try f(&param)
    }
    public func sync_3<T, R>(inout param: T, @noescape f: (inout T) throws -> R) rethrows -> R {
      pthread_mutex_lock(&unsafeMutex)
      defer { pthread_mutex_unlock(&unsafeMutex) }
      return try f(&param)
    }
    public func sync_4<T, U>(inout param1: T, inout _ param2: U, @noescape f: (inout T, inout U) throws -> Void) rethrows -> Void {
      pthread_mutex_lock(&unsafeMutex)
      defer { pthread_mutex_unlock(&unsafeMutex) }
      return try f(&param1, &param2)
    }
  }
  
#endif
