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
    let min = pathComps.reduce(pathComps[0].count) { (result, comps) in result < comps.count ? result : comps.count }
    let pathCompsWithMinCount = pathComps.filter { $0.count == min }
    let possibleParent = NSURL.fileURL(withPathComponents: pathCompsWithMinCount[0])!

    let minPathComponents = Set(pathComps.map { $0[min - 1] })
    if minPathComponents.count == 1 {
      return possibleParent.dir ? possibleParent : possibleParent.deletingLastPathComponent()
    }

    return possibleParent.deletingLastPathComponent()
  }
}
