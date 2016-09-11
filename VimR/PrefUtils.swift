/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PrefUtils {

  private static let whitespaceCharSet = NSCharacterSet.whitespaceCharacterSet()

  static func ignorePatterns(fromString str: String) -> Set<FileItemIgnorePattern> {
    if str.stringByTrimmingCharactersInSet(self.whitespaceCharSet).characters.count == 0 {
      return Set()
    }

    let patterns: [FileItemIgnorePattern] = str
      .componentsSeparatedByString(",")
      .flatMap {
        let trimmed = $0.stringByTrimmingCharactersInSet(self.whitespaceCharSet)
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
      .sort()
      .joinWithSeparator(", ")
  }
}