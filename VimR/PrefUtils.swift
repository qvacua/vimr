/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PrefUtils {

  fileprivate static let whitespaceCharSet = CharacterSet.whitespaces

  static func ignorePatterns(fromString str: String) -> Set<FileItemIgnorePattern> {
    if str.trimmingCharacters(in: self.whitespaceCharSet).characters.count == 0 {
      return Set()
    }

    let patterns: [FileItemIgnorePattern] = str
      .components(separatedBy: ",")
      .flatMap {
        let trimmed = $0.trimmingCharacters(in: self.whitespaceCharSet)
        if trimmed.characters.count == 0 {
          return nil
        }

        return FileItemIgnorePattern(pattern: trimmed)
    }
    
    return Set(patterns)
  }

  static func ignorePatternString(fromSet set: Set<FileItemIgnorePattern>) -> String {
    return Array(set)
      .map { $0.pattern }
      .sorted()
      .joined(separator: ", ")
  }
}
