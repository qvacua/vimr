/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Matcher {

  static let uppercaseCharSet = CharacterSet.uppercaseLetters

  enum ExactMatchResult {
    case none
    case exact
    case prefix
    case suffix
    case contains
  }

  static func exactMatchIgnoringCase(_ target: String, pattern: String) -> ExactMatchResult {
    let ltarget = target.lowercased()
    let lpattern = pattern.lowercased()

    if ltarget == lpattern {
      return .exact
    }

    if ltarget.hasPrefix(lpattern) {
      return .prefix
    }

    if ltarget.hasSuffix(lpattern) {
      return .suffix
    }

    if ltarget.contains(lpattern) {
      return .contains
    }

    return .none
  }

  static func numberOfUppercaseMatches(_ target: String, pattern: String) -> Int {
    var tscalars = target.unicodeScalars.filter { self.uppercaseCharSet.contains($0) }

    let count = tscalars.count
    guard count > 0 else {
      return 0
    }

    let pscalars = pattern.uppercased().unicodeScalars

    pscalars.forEach {
      if let idx = tscalars.index(of: $0) {
        tscalars.remove(at: idx)
      }
    }

    return count - tscalars.count
  }

  /// Matches `pattern` to `target` in a fuzzy way.
  /// - returns: number of matched characters where first character match gets a bonus of 5
  static func fuzzyIgnoringCase(_ target: String, pattern: String) -> Int {
    let tlower = target.lowercased()
    let plower = pattern.lowercased()

    let tchars = tlower.unicodeScalars
    let pchars = plower.unicodeScalars

    var result = 0
    var pidx = pchars.startIndex
    for tchar in tchars {
      if pchars[pidx] == tchar {
        result += 1
        pidx = pchars.index(after: pidx)
      }
    }

    if tchars.first == pchars.first {
      result += 5
    }

    return result
  }

  /// Wagner-Fischer algorithm.
  /// We use the 32 bit representation (`String.unicodeScalars`) of both parameters to compare them.
  ///
  /// - returns: the distance of pattern from target
  /// - seealso: https://en.wikipedia.org/wiki/Wagner–Fischer_algorithm
  static func wagnerFisherDistance(_ target: String, pattern: String) -> Int {
    let s = target.unicodeScalars
    let t = pattern.unicodeScalars

    let m = s.count

    var prevRow = Array(repeating: 0, count: m &+ 1)
    var curRow = Array(repeating: 0, count: m &+ 1)

    for i in 0 ... m {
      prevRow[i] = i
    }

    for (j, tchar) in t.enumerated() {
      curRow[0] = j &+ 1

      for (i, schar) in s.enumerated() {
        if schar == tchar {
          curRow[i &+ 1] = prevRow[i]
        } else {
          curRow[i &+ 1] = min(curRow[i] &+ 1, prevRow[i &+ 1] &+ 1, prevRow[i] &+ 1)
        }
      }

      prevRow = curRow
    }

    return curRow[m]
  }
}
