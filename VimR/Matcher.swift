/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Matcher {
  
  static let uppercaseCharSet = NSCharacterSet.uppercaseLetterCharacterSet()

  enum ExactMatchResult {
    case none
    case exact
    case prefix
    case suffix
    case contains
  }

  static func exactMatchIgnoringCase(target: String, pattern: String) -> ExactMatchResult {
    let ltarget = target.lowercaseString
    let lpattern = pattern.lowercaseString
    if ltarget == lpattern {
      return .exact
    }

    if ltarget.hasPrefix(lpattern) {
      return .prefix
    }

    if ltarget.hasSuffix(lpattern) {
      return .suffix
    }

    if ltarget.containsString(lpattern) {
      return .contains
    }

    return .none
  }

  static func numberOfUppercaseMatches(target: String, pattern: String) -> Int {
    var tscalars = target.unicodeScalars.filter { uppercaseCharSet.longCharacterIsMember($0.value) }
    
    let count = tscalars.count
    guard count > 0 else {
      return 0
    }
    
    let pscalars = pattern.uppercaseString.unicodeScalars
    
    pscalars.forEach { scalar in
      if let idx = tscalars.indexOf(scalar) {
        tscalars.removeAtIndex(idx)
      }
    }
    
    return count - tscalars.count
  }
  
  /// Matches `pattern` to `target` in a fuzzy way.
  /// - returns: `Array` of `Range<String.UnicodeScalarIndex>`
  static func fuzzyIgnoringCase(target: String, pattern: String) -> (matches: Int, ranges: [Range<Int>]) {
    let tlower = target.lowercaseString
    let plower = pattern.lowercaseString
    
    let tchars = tlower.unicodeScalars
    let pchars = plower.unicodeScalars
    
    var flags = Array(count: tchars.count, repeatedValue: false)
    
    var pidx = pchars.startIndex
    for (i, tchar) in tchars.enumerate() {
      if pchars[pidx] == tchar {
        flags[i] = true
        pidx = pidx.successor()
      }
    }
    
    var ranges: [Range<Int>] = []
    var matches = 0
    
    var lastTrue = -1
    var curTrue = -1
    
    for (i, isTrue) in flags.enumerate() {
      if isTrue {
        matches = matches &+ 1
        if lastTrue == -1 {
          lastTrue = i
        }
        curTrue = i
        
        if i == flags.count &- 1 {
          if lastTrue > -1 && curTrue > -1 {
            ranges.append(lastTrue...curTrue)
            lastTrue = -1
            curTrue = -1
          }
        }
      } else {
        if lastTrue > -1 && curTrue > -1 {
          ranges.append(lastTrue...curTrue)
          lastTrue = -1
          curTrue = -1
        }
      }
    }
    
    return (matches, ranges)
  }
  
  /// Wagner-Fischer algorithm.
  /// We use the 32 bit representation (`String.unicodeScalars`) of both parameters to compare them.
  ///
  /// - returns: the distance of pattern from target
  /// - seealso: https://en.wikipedia.org/wiki/Wagner–Fischer_algorithm
  static func wagnerFisherDistance(target: String, pattern: String) -> Int {
    let s = target.unicodeScalars
    let t = pattern.unicodeScalars
    
    let m = s.count
    
    var prevRow = Array(count: m &+ 1, repeatedValue: 0)
    var curRow = Array(count: m &+ 1, repeatedValue: 0)
    
    for i in 0...m {
      prevRow[i] = i
    }
    
    for (j, tchar) in t.enumerate() {
      curRow[0] = j &+ 1
      
      for (i, schar) in s.enumerate() {
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
