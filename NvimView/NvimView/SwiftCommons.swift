/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

extension Array where Element: Hashable {

  // From https://stackoverflow.com/a/46354989/9850227
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return self.filter { seen.insert($0).inserted }
  }
}

extension Array {

  func data() -> Data {
    return self.withUnsafeBufferPointer(Data.init)
  }
}

extension RandomAccessCollection where Index == Int {

  func parallelMap<T>(
    chunkSize: Int = 1,
    _ transform: @escaping (Element) -> T
  ) -> [T] {
    let count = self.count
    guard count > chunkSize else { return self.map(transform) }

    var result = Array<T?>(repeating: nil, count: count)

    // If we don't use Array.withUnsafeMutableBufferPointer,
    // then we get crashes.
    result.withUnsafeMutableBufferPointer { pointer in
      if chunkSize == 1 {
        DispatchQueue.concurrentPerform(iterations: count) { i in
          pointer[i] = transform(self[i])
        }
      } else {
        let chunkCount = Int(ceil(Double(self.count) / Double(chunkSize)))
        DispatchQueue.concurrentPerform(iterations: chunkCount) { chunkIndex in
          let start = Swift.min(chunkIndex * chunkSize, count)
          let end = Swift.min(start + chunkSize, count)

          (start..<end).forEach { i in pointer[i] = transform(self[i]) }
        }
      }
    }

    return result.map { $0! }
  }

  func groupedRanges<T: Equatable>(
    with marker: (Index, Element) -> T
  ) -> [CountableClosedRange<Index>] {
    if self.isEmpty {
      return []
    }

    if self.count == 1 {
      return [self.startIndex...self.startIndex]
    }

    var result = [CountableClosedRange<Index>]()
    result.reserveCapacity(self.count / 2)

    let inclusiveEndIndex = self.endIndex - 1
    var lastStartIndex = self.startIndex
    var lastEndIndex = self.startIndex
    var lastMarker = marker(0, self.first!) // self is not empty!
    for i in self.startIndex..<self.endIndex {
      defer { lastEndIndex = i }

      let currentMarker = marker(i, self[i])

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

