/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileUtils {
  
  fileprivate static let keysToGet = [
    URLResourceKey.isDirectoryKey,
    URLResourceKey.isHiddenKey,
    URLResourceKey.isAliasFileKey,
    URLResourceKey.isSymbolicLinkKey
  ]
  
  fileprivate static let scanOptions: FileManager.DirectoryEnumerationOptions = [
    FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants,
    FileManager.DirectoryEnumerationOptions.skipsPackageDescendants
  ]
  
  fileprivate static let fileManager = FileManager.default

  static let userHomeUrl = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
  
  static func directDescendants(_ url: URL) -> [URL] {
    guard let childUrls = try? self.fileManager.contentsOfDirectory(
      at: url, includingPropertiesForKeys: self.keysToGet, options: self.scanOptions
    ) else {
      // FIXME error handling
      return []
    }
    
    return childUrls
  }
  
  static func fileExistsAtUrl(_ url: URL) -> Bool {
    guard url.isFileURL else {
      return false
    }

    let path = url.path
    return self.fileManager.fileExists(atPath: path)
  }

  static func commonParent(ofUrls urls: [URL]) -> URL {
    guard urls.count > 0 else {
      return URL(fileURLWithPath: "/", isDirectory: true)
    }

    let pathComps = urls.map { $0.pathComponents }
    let min = pathComps.map { $0.count }.min()!
    let pathCompsOnlyMin = pathComps.map { $0[0..<min] }
    let commonIdx = (0..<min).reversed().reduce(min - 1) { (result, idx) in
      if Set(pathCompsOnlyMin.map { $0[idx] }).count > 1 {
        return idx - 1
      } else {
        return result
      }
    }

    let result = pathCompsOnlyMin[0]
    let possibleParent = NSURL.fileURL(withPathComponents: Array(result[0...commonIdx]))!

    return possibleParent.dir ? possibleParent : possibleParent.deletingLastPathComponent()
  }
}
