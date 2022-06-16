/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import WildmatchC

public struct Filter: CustomStringConvertible {
  public let base: URL
  public let pattern: String

  public let isAllow: Bool
  public let isOnlyForDirectories: Bool
  public let isRelativeToBase: Bool

  public init(base: URL, pattern: String) {
    self.base = base

    var effectivePattern: String

    self.isAllow = pattern.first == "!"
    effectivePattern = self.isAllow ? String(pattern.dropFirst()) : pattern

    self.isOnlyForDirectories = effectivePattern.last == "/"
    effectivePattern =
      self.isOnlyForDirectories ? String(effectivePattern.dropLast(1)) : effectivePattern

    self.isRelativeToBase = effectivePattern.contains("/")
    if self.isRelativeToBase {
      effectivePattern = base.path
        + (effectivePattern.first == "/" ? effectivePattern : "/" + effectivePattern)
    }

    self.pattern = effectivePattern
    self.patternCstr = Array(self.pattern.utf8CString)
  }

  public func disallows(_ url: URL) -> Bool {
    if self.isOnlyForDirectories {
      guard url.hasDirectoryPath else { return false }
    }

    if self.isRelativeToBase {
      let matches = self.matches(url.path)
      if self.isAllow { return !matches } else { return matches }
    }

    let matches = self.matches(url.lastPathComponent)
    if self.isAllow { return false } else { return matches }
  }

  public func explicitlyAllows(_ url: URL) -> Bool {
    if self.isOnlyForDirectories {
      guard url.hasDirectoryPath else { return false }
    }

    if self.isRelativeToBase {
      if self.isAllow { return self.matches(url.path) }
      return false
    }

    if self.isAllow { return self.matches(url.lastPathComponent) } else { return false }
  }

  /// Ignores whether the pattern is only applicable for directories.
  public func disallows(_ string: String) -> Bool {
    if self.isAllow { return false } else { return self.matches(string) }
  }

  /// Ignores whether the pattern is only applicable for directories.
  public func explicitlyAllows(_ string: String) -> Bool {
    if self.isAllow { return self.matches(string) }
    return false
  }

  public func matches(_ url: URL) -> Bool {
    if self.isOnlyForDirectories {
      guard url.hasDirectoryPath else { return false }
    }

    if self.isRelativeToBase {
      return url.path.withCString { stringCstr in
        wildmatch(patternCstr, stringCstr, WM_WILDSTAR) == WM_MATCH
      }
    }

    return url.lastPathComponent.withCString { stringCstr in
      wildmatch(patternCstr, stringCstr, WM_WILDSTAR) == WM_MATCH
    }
  }

  /// Ignores whether the pattern is only applicable for directories.
  public func matches(_ string: String) -> Bool {
    string.withCString {
      stringCstr in
      wildmatch(patternCstr, stringCstr, WM_WILDSTAR) == WM_MATCH
    }
  }

  public var description: String {
    "Ignore(isAllow: \(self.isAllow), isOnlyDirectory: \(self.isOnlyForDirectories), "
      + "isAbsolute: \(self.isRelativeToBase), pattern: \(self.pattern), baseUrl: \(self.base))"
  }

  private let patternCstr: [CChar]
}
