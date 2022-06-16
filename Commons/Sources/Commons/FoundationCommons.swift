/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

public extension Array where Element: Hashable {
  // From https://stackoverflow.com/a/46354989
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return self.filter { seen.insert($0).inserted }
  }
}

public extension Array {
  func data() -> Data { self.withUnsafeBufferPointer(Data.init) }
}

public extension RandomAccessCollection where Index == Int {
  func parallelMap<T>(chunkSize: Int = 1, _ transform: @escaping (Element) -> T) -> [T] {
    let count = self.count
    guard count > chunkSize else { return self.map(transform) }

    var result = [T?](repeating: nil, count: count)

    // If we don't use Array.withUnsafeMutableBufferPointer,
    // then we get crashes.
    result.withUnsafeMutableBufferPointer { pointer in
      if chunkSize == 1 {
        DispatchQueue.concurrentPerform(iterations: count) { i in pointer[i] = transform(self[i]) }
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

  func groupedRanges<T: Equatable>(with marker: (Element) -> T) -> [ClosedRange<Index>] {
    if self.isEmpty { return [] }
    if self.count == 1 { return [self.startIndex...self.startIndex] }

    var result = [ClosedRange<Index>]()
    result.reserveCapacity(self.count / 2)

    let inclusiveEndIndex = self.endIndex - 1
    var lastStartIndex = self.startIndex
    var lastEndIndex = self.startIndex
    var lastMarker = marker(self.first!) // self is not empty!
    for i in self.startIndex..<self.endIndex {
      let currentMarker = marker(self[i])

      if lastMarker == currentMarker {
        if i == inclusiveEndIndex { result.append(lastStartIndex...i) }
      } else {
        result.append(lastStartIndex...lastEndIndex)
        lastMarker = currentMarker
        lastStartIndex = i

        if i == inclusiveEndIndex { result.append(i...i) }
      }

      lastEndIndex = i
    }

    return result
  }
}

public extension NSRange {
  static let notFound = NSRange(location: NSNotFound, length: 0)

  var inclusiveEndIndex: Int { self.location + self.length - 1 }
}

public extension URL {
  func isParent(of url: URL) -> Bool {
    guard self.isFileURL, url.isFileURL else { return false }

    let myPathComps = self.pathComponents
    let targetPathComps = url.pathComponents

    guard targetPathComps.count == myPathComps.count + 1 else { return false }

    return Array(targetPathComps[0..<myPathComps.count]) == myPathComps
  }

  func isAncestor(of url: URL) -> Bool {
    guard self.isFileURL, url.isFileURL else { return false }

    let myPathComps = self.pathComponents
    let targetPathComps = url.pathComponents

    guard targetPathComps.count > myPathComps.count else { return false }

    return Array(targetPathComps[0..<myPathComps.count]) == myPathComps
  }

  func isContained(in parentUrl: URL) -> Bool {
    if parentUrl == self { return false }

    let pathComps = self.pathComponents
    let parentPathComps = parentUrl.pathComponents

    guard pathComps.count > parentPathComps.count else { return false }

    guard Array(pathComps[0..<parentPathComps.endIndex]) == parentPathComps else { return false }

    return true
  }

  var parent: URL {
    if self.path == "/" { return self }

    return self.deletingLastPathComponent()
  }

  var shellEscapedPath: String { self.path.shellEscapedPath }

  var isRegularFile: Bool {
    (try? self.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false
  }

  var isHidden: Bool { (try? self.resourceValues(forKeys: [.isHiddenKey]))?.isHidden ?? false }

  var isPackage: Bool { (try? self.resourceValues(forKeys: [.isPackageKey]))?.isPackage ?? false }
}

public extension ValueTransformer {
  static var keyedUnarchiveFromDataTransformer
    = ValueTransformer(forName: .keyedUnarchiveFromDataTransformerName)!
}

private let log = OSLog(subsystem: "com.qvacua.vimr.commons", category: "general")
