/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

private let workspace = NSWorkspace.shared
private let iconsCache = NSCache<NSURL, NSImage>()

public final class FileUtils {
  private static let keysToGet: [URLResourceKey] = [
    .isDirectoryKey,
    .isHiddenKey,
    .isAliasFileKey,
    .isSymbolicLinkKey,
  ]

  private static let scanOptions: FileManager.DirectoryEnumerationOptions = [
    .skipsSubdirectoryDescendants,
    .skipsPackageDescendants,
  ]

  private static let fileManager = FileManager.default
  public static let userHomeUrl = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
  public static func tempDir() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
  }

  public static func directDescendants(of url: URL) -> [URL] {
    guard let childUrls = try? self.fileManager.contentsOfDirectory(
      at: url, includingPropertiesForKeys: self.keysToGet, options: self.scanOptions
    ) else { return [] }

    return childUrls
  }

  public static func fileExists(at url: URL) -> Bool {
    guard url.isFileURL else { return false }

    let path = url.path
    return self.fileManager.fileExists(atPath: path)
  }

  public static func commonParent(of urls: [URL]) -> URL {
    guard urls.count > 0 else { return URL(fileURLWithPath: "/", isDirectory: true) }

    let pathComps = urls.map { $0.deletingLastPathComponent().pathComponents }
    let min = pathComps.map(\.count).min()!
    let pathCompsOnlyMin = pathComps.map { $0[0..<min] }
    let commonIdx = (0..<min).reversed().reduce(min - 1) { result, idx in
      if Set(pathCompsOnlyMin.map { $0[idx] }).count > 1 { return idx - 1 }
      else { return result }
    }

    let result = pathCompsOnlyMin[0]
    let possibleParent = NSURL.fileURL(withPathComponents: Array(result[0...commonIdx]))!

    return possibleParent.isDir ? possibleParent : possibleParent.parent
  }

  public static func icon(forType type: String) -> NSImage { workspace.icon(forFileType: type) }

  public static func icon(forUrl url: URL) -> NSImage? {
    if let cached = iconsCache.object(forKey: url as NSURL) { return cached }

    let path = url.path
    let icon = workspace.icon(forFile: path)
    icon.size = CGSize(width: 16, height: 16)
    iconsCache.setObject(icon, forKey: url as NSURL)

    return icon
  }
}
