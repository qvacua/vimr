//
// Created by Tae Won Ha on 19.08.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {

  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return self.filter { seen.insert($0).inserted }
  }
}

extension Array {

  /// Does not retain the order of elements.
  func parallelMap<T>(_ transform: @escaping (Element) -> T) -> [T] {
    var result = Array<T>()
    result.reserveCapacity(self.count)

    var lock = OS_SPINLOCK_INIT
    DispatchQueue.concurrentPerform(iterations: self.count) { i in
      let mapped = transform(self[i])
      OSSpinLockLock(&lock)
      result.append(mapped)
      OSSpinLockUnlock(&lock)
    }

    return result
  }
}

extension ArraySlice {

  func groupedRanges<T: Equatable>(with marker: (Int, Element, ArraySlice<Element>) -> T) -> [CountableClosedRange<Int>] {
    if self.isEmpty {
      return []
    }

    var result = [CountableClosedRange<Int>]()
    result.reserveCapacity(self.count / 2)

    let inclusiveEndIndex = self.endIndex - 1
    var lastStartIndex = 0
    var lastEndIndex = 0
    var lastMarker = marker(0, self.first!, self) // self is not empty!
    for (i, element) in self.enumerated() {
      defer { lastEndIndex = i }

      let currentMarker = marker(i, element, self)

      if lastMarker == currentMarker {
        if i == inclusiveEndIndex {
          result.append(lastStartIndex...i)
        }
      } else {
        result.append(lastStartIndex...lastEndIndex)
        lastMarker = currentMarker
        lastStartIndex = i

        if i == inclusiveEndIndex {
          result.append(i...i)
        }
      }
    }

    return result
  }
}

extension Array {

  func groupedRanges<T: Equatable>(with marker: (Int, Element, [Element]) -> T) -> [CountableClosedRange<Int>] {
    if self.isEmpty {
      return []
    }

    var result = [CountableClosedRange<Int>]()
    result.reserveCapacity(self.count / 2)

    let inclusiveEndIndex = self.endIndex - 1
    var lastStartIndex = 0
    var lastEndIndex = 0
    var lastMarker = marker(0, self.first!, self) // self is not empty!
    for (i, element) in self.enumerated() {
      defer { lastEndIndex = i }

      let currentMarker = marker(i, element, self)

      if lastMarker == currentMarker {
        if i == inclusiveEndIndex {
          result.append(lastStartIndex...i)
        }
      } else {
        result.append(lastStartIndex...lastEndIndex)
        lastMarker = currentMarker
        lastStartIndex = i

        if i == inclusiveEndIndex {
          result.append(i...i)
        }
      }
    }

    return result
  }
}
