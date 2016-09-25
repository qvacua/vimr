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
    var tscalars = target.unicodeScalars.filter { uppercaseCharSet.contains(UnicodeScalar($0.value)!) }
    
    let count = tscalars.count
    guard count > 0 else {
      return 0
    }
    
    let pscalars = pattern.uppercased().unicodeScalars
    
    pscalars.forEach { scalar in
      if let idx = tscalars.index(of: scalar) {
        tscalars.remove(at: idx)
      }
    }
    
    return count - tscalars.count
  }
  
  /// Matches `pattern` to `target` in a fuzzy way.
  /// - returns: `Array` of `Range<String.UnicodeScalarIndex>`
  static func fuzzyIgnoringCase(_ target: String, pattern: String) -> (matches: Int, ranges: [CountableRange<Int>]) {
    let tlower = target.lowercased()
    let plower = pattern.lowercased()
    
    let tchars = tlower.unicodeScalars
    let pchars = plower.unicodeScalars
    
    var flags = Array(repeating: false, count: tchars.count)
    
    var pidx = pchars.startIndex
    for (i, tchar) in tchars.enumerated() {
      if pchars[pidx] == tchar {
        flags[i] = true
        pidx = pchars.index(after: pidx)
      }
    }
    
    var ranges: [CountableRange<Int>] = []
    var matches = 0
    
    var lastTrue = -1
    var curTrue = -1
    
    for (i, isTrue) in flags.enumerated() {
      if isTrue {
        matches = matches &+ 1
        if lastTrue == -1 {
          lastTrue = i
        }
        curTrue = i
        
        if i == flags.count &- 1 {
          if lastTrue > -1 && curTrue > -1 {
            ranges.append(CountableRange(lastTrue...curTrue))
            lastTrue = -1
            curTrue = -1
          }
        }
      } else {
        if lastTrue > -1 && curTrue > -1 {
          ranges.append(CountableRange(lastTrue...curTrue))
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
  static func wagnerFisherDistance(_ target: String, pattern: String) -> Int {
    let s = target.unicodeScalars
    let t = pattern.unicodeScalars
    
    let m = s.count
    
    var prevRow = Array(repeating: 0, count: m &+ 1)
    var curRow = Array(repeating: 0, count: m &+ 1)
    
    for i in 0...m {
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
