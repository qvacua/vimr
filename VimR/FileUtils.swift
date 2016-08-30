/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileUtils {
  
  private static let keysToGet = [
    NSURLIsDirectoryKey,
    NSURLIsHiddenKey,
    NSURLIsAliasFileKey,
    NSURLIsSymbolicLinkKey
  ]
  
  private static let scanOptions: NSDirectoryEnumerationOptions = [
    NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants,
    NSDirectoryEnumerationOptions.SkipsPackageDescendants
  ]
  
  private static let fileManager = NSFileManager.defaultManager()
  
  static func directDescendants(url: NSURL) -> [NSURL] {
    guard let childUrls = try? self.fileManager.contentsOfDirectoryAtURL(
      url, includingPropertiesForKeys: self.keysToGet, options: self.scanOptions
    ) else {
      // FIXME error handling
      return []
    }
    
    return childUrls
  }
  
  static func fileExistsAtUrl(url: NSURL) -> Bool {
    guard url.fileURL else {
      return false
    }

    guard let path = url.path else {
      return false
    }
    
    return self.fileManager.fileExistsAtPath(path)
  }

  static func commonParent(ofUrls urls: [NSURL]) -> NSURL {
    guard urls.count > 0 else {
      return NSURL(fileURLWithPath: "/", isDirectory: true)
    }

    let pathComps = urls.map { $0.pathComponents! }
    let min = pathComps.reduce(pathComps[0].count) { (result, comps) in result < comps.count ? result : comps.count }
    let pathCompsWithMinCount = pathComps.filter { $0.count == min }
    let possibleParent = NSURL.fileURLWithPathComponents(pathCompsWithMinCount[0])!

    let minPathComponents = Set(pathComps.map { $0[min - 1] })
    if minPathComponents.count == 1 {
      return possibleParent.dir ? possibleParent : possibleParent.URLByDeletingLastPathComponent!
    }

    return possibleParent.URLByDeletingLastPathComponent!
  }
}
