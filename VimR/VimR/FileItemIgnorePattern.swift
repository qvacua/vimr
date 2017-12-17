/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

private let whitespaceCharSet = CharacterSet.whitespaces

class FileItemIgnorePattern: Hashable, CustomStringConvertible {

  static func ==(lhs: FileItemIgnorePattern, rhs: FileItemIgnorePattern) -> Bool {
    return lhs.pattern == rhs.pattern
  }

  static func from(string str: String) -> Set<FileItemIgnorePattern> {
    if str.trimmingCharacters(in: whitespaceCharSet).count == 0 {
      return Set()
    }

    let patterns: [FileItemIgnorePattern] = str
      .components(separatedBy: ",")
      .flatMap {
        let trimmed = $0.trimmingCharacters(in: whitespaceCharSet)
        if trimmed.count == 0 {
          return nil
        }

        return FileItemIgnorePattern(pattern: trimmed)
      }

    return Set(patterns)
  }

  static func toString(_ set: Set<FileItemIgnorePattern>) -> String {
    return Array(set)
      .map { $0.pattern }
      .sorted()
      .joined(separator: ", ")
  }

  var hashValue: Int {
    return self.pattern.hashValue
  }

  var description: String {
    return "<FileItemIgnorePattern: pattern=\(self.pattern), folderPattern=\(self.folderPattern)>"
  }

  let folderPattern: Bool
  let pattern: String

  private let patternAsFileSysRep: UnsafeMutablePointer<Int8>

  init(pattern: String) {
    self.pattern = pattern
    self.folderPattern = pattern.hasPrefix("*/")

    let fileSysRep = (pattern as NSString).fileSystemRepresentation
    let len = Int(strlen(fileSysRep))

    self.patternAsFileSysRep = UnsafeMutablePointer<Int8>.allocate(capacity: len + 1)
    memcpy(self.patternAsFileSysRep, fileSysRep, len)
    self.patternAsFileSysRep[len] = 0
  }

  deinit {
    let len = Int(strlen(self.patternAsFileSysRep))
    self.patternAsFileSysRep.deallocate(capacity: len + 1)
  }

  func match(absolutePath path: String) -> Bool {
    let matches: Int32
    let absolutePath = path as NSString

    if self.folderPattern {
      matches = fnmatch(self.patternAsFileSysRep,
                        absolutePath.fileSystemRepresentation,
                        FNM_LEADING_DIR | FNM_NOESCAPE)
    } else {
      matches = fnmatch(self.patternAsFileSysRep,
                        (absolutePath.lastPathComponent as NSString).fileSystemRepresentation,
                        FNM_NOESCAPE)
    }

    return matches != FNM_NOMATCH
  }
}
