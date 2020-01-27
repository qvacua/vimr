/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

extension URL {

  var direntType: UInt8 { (self as NSURL).direntType() }

  func isDirectParent(of url: URL) -> Bool {
    guard self.isFileURL && url.isFileURL else { return false }

    let myPathComps = self.pathComponents
    let targetPathComps = url.pathComponents

    guard targetPathComps.count == myPathComps.count + 1 else { return false }

    return Array(targetPathComps[0..<myPathComps.count]) == myPathComps
  }

  func isParent(of url: URL) -> Bool {
    guard self.isFileURL && url.isFileURL else { return false }

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

  var isDir: Bool { self.resourceValue(URLResourceKey.isDirectoryKey.rawValue) }

  var isHidden: Bool { self.resourceValue(URLResourceKey.isHiddenKey.rawValue) }

  var isPackage: Bool { self.resourceValue(URLResourceKey.isPackageKey.rawValue) }

  /// Wrapper function for NSURL.getResourceValue for Bool values.
  /// Returns also `false` when
  /// - there is no value for the given `key` or
  /// - the value cannot be converted to `NSNumber`.
  ///
  /// - parameters:
  ///   - key: The `key`-parameter of `NSURL.getResourceValue`.
  private func resourceValue(_ key: String) -> Bool {
    var rsrc: AnyObject?

    do {
      try (self as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey(rawValue: key))
    } catch let error as NSError {
      // FIXME error handling
      log.error("ERROR while getting \(key): \(error)")
      return false
    }

    if let result = rsrc as? NSNumber { return result.boolValue }

    return false
  }
}

extension ValueTransformer {

  static var keyedUnarchiveFromDataTransformer
    = ValueTransformer(forName: .keyedUnarchiveFromDataTransformerName)!
}

private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.general)
