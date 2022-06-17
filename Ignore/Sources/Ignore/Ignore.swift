/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation

public class Ignore {
  public static let defaultIgnoreFileNames = [".ignore", ".gitignore"]
  public static let vcsFolderPattern = [".svn/", ".hg/", ".git/"]

  public static func globalGitignoreCollection(base: URL) -> Ignore? {
    let gitRoot = GitUtils.gitRootUrl(base: base)
    let urls = [
      GitUtils.gitDirInfoExcludeUrl(base: base, gitRoot: gitRoot),
      GitUtils.globalGitignoreFileUrl(),
    ].compactMap { $0 }

    if urls.isEmpty { return nil }

    if let gitRoot = gitRoot {
      let vcsFolderFilters = self.vcsFolderPattern.map { Filter(base: gitRoot, pattern: $0) }
      return Ignore(base: gitRoot, parent: nil, ignoreFileUrls: urls, prepend: vcsFolderFilters)
    }

    let vcsFolderFilters = self.vcsFolderPattern.map { Filter(base: base, pattern: $0) }
    return Ignore(base: base, parent: nil, ignoreFileUrls: urls, prepend: vcsFolderFilters)
  }

  public let filters: [Filter]

  /// `ignoreFileUrls[n]` overrides `ignoreFileUrls[n + 1]`.
  /// `Ignore`s of `parent` are overridden, if applicable, by the `Ignore`s found in `base`.
  public init?(
    base: URL,
    parent: Ignore?,
    ignoreFileUrls: [URL],
    prepend: [Filter] = [],
    append: [Filter] = []
  ) {
    if ignoreFileUrls.isEmpty { return nil }
    let urls = ignoreFileUrls.filter { fm.fileExists(atPath: $0.path) }.reversed()

    self.filters = (parent?.filters ?? [])
      + prepend.reversed()
      + urls.flatMap {
        FileLineReader(url: $0, encoding: .utf8)
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty && !$0.starts(with: "#") }
          .map { Filter(base: base, pattern: $0) }
      }
      + append.reversed()

    if self.filters.isEmpty { return nil }

    if let lastAllowIndex = self.filters
      .enumerated()
      .filter({ _, ignore in ignore.isAllow })
      .map(\.offset)
      .max()
    {
      self.mixedIgnores = self.filters[0...lastAllowIndex]
      self.remainingDisallowIgnores = self.filters[(lastAllowIndex + 1)...]
    } else {
      self.mixedIgnores = ArraySlice()
      self.remainingDisallowIgnores = self.filters[0...]
    }
  }

  /// `ignoreFileNames[n]` overrides `ignoreFileNames[n + 1]`.
  /// `Ignore`s of `parent` are overridden, if applicable, by the `Ignore`s found in `base`.
  public convenience init?(
    base: URL,
    parent: Ignore?,
    ignoreFileNames: [String] = defaultIgnoreFileNames
  ) {
    self.init(
      base: base,
      parent: parent,
      ignoreFileUrls: ignoreFileNames.map { base.appendingPathComponent($0) }
    )
  }

  public func excludes(_ url: URL) -> Bool {
    var isExcluded = false

    for ignore in self.mixedIgnores {
      if ignore.isAllow {
        if ignore.matches(url) { isExcluded = false }
      } else {
        if ignore.matches(url) { isExcluded = true }
      }
    }

    if isExcluded { return true }

    for ignore in self.remainingDisallowIgnores {
      if ignore.matches(url) { return true }
    }

    return false
  }

  let mixedIgnores: ArraySlice<Filter>
  let remainingDisallowIgnores: ArraySlice<Filter>
}

private let fm = FileManager.default
