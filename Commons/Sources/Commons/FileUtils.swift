/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import AppKit
import Cocoa
import UniformTypeIdentifiers

// icon(forFile:) is thread-safe: https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfile:)
// icon(for:) probably is thread-safe
private nonisolated(unsafe) let workspace = NSWorkspace.shared

// NSCache is thread-safe: https://developer.apple.com/documentation/foundation/nscache#overview
private nonisolated(unsafe) let iconsCache = NSCache<NSURL, NSImage>()

// FileManager is thread-safe:
// https://developer.apple.com/documentation/foundation/filemanager#1651181
private nonisolated(unsafe) let fm = FileManager.default

public final class FileUtils {
  private static let keysToGet: [URLResourceKey] = [
    .isRegularFileKey,
    .isDirectoryKey,
    .isPackageKey,
    .isHiddenKey,
  ]

  private static let scanOptions: FileManager.DirectoryEnumerationOptions = [
    .skipsSubdirectoryDescendants,
    .skipsPackageDescendants,
  ]

  public static let userHomeUrl = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
  public static func tempDir() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
  }

  public static func directDescendants(of url: URL) -> [URL] {
    guard let childUrls = try? fm.contentsOfDirectory(
      at: url, includingPropertiesForKeys: self.keysToGet, options: self.scanOptions
    ) else { return [] }

    return childUrls
  }

  public static func fileExists(at url: URL) -> Bool {
    guard url.isFileURL else { return false }

    let path = url.path
    return fm.fileExists(atPath: path)
  }

  public static func commonParent(of urls: [URL]) -> URL {
    guard urls.count > 0 else { return URL(fileURLWithPath: "/", isDirectory: true) }

    let pathComps = urls.map { $0.deletingLastPathComponent().pathComponents }
    let min = pathComps.map(\.count).min()!
    let pathCompsOnlyMin = pathComps.map { $0[0..<min] }
    let commonIdx = (0..<min).reversed().reduce(min - 1) { result, idx in
      if Set(pathCompsOnlyMin.map { $0[idx] }).count > 1 { idx - 1 }
      else { result }
    }

    let result = pathCompsOnlyMin[0]
    let possibleParent = NSURL.fileURL(withPathComponents: Array(result[0...commonIdx]))!

    return possibleParent.hasDirectoryPath ? possibleParent : possibleParent.parent
  }

  public static func icon(forType type: String) -> NSImage { workspace
    .icon(for: UTType(type) ?? UTType.text)
  }

  public static func icon(forUrl url: URL) -> NSImage? {
    if let cached = iconsCache.object(forKey: url as NSURL) { return cached }

    let path = url.path
    let icon = workspace.icon(forFile: path)
    icon.size = CGSize(width: 16, height: 16)
    iconsCache.setObject(icon, forKey: url as NSURL)

    return icon
  }
}
