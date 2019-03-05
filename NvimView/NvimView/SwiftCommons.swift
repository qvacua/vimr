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

extension RandomAccessCollection where Index == Int {

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

