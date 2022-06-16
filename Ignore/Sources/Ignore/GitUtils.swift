/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation

public class GitUtils {
  static func globalGitignoreFileUrl() -> URL? {
    guard let path = shellCommandOutput(
      "git config --get core.excludesFile",
      workingDirectory: fm.homeDirectoryForCurrentUser
    ),
      FileManager.default.fileExists(atPath: path)
    else { return nil }

    return URL(fileURLWithPath: path)
  }

  static func gitDirInfoExcludeUrl(base: URL, gitRoot: URL? = nil) -> URL? {
    guard let gitRoot = gitRoot == nil ? gitRootUrl(base: base) : gitRoot,
          let gitDirName = shellCommandOutput("git rev-parse --git-dir", workingDirectory: gitRoot)
    else { return nil }

    let url = gitRoot.appendingPathComponent("\(gitDirName)/info/exclude")
    guard fm.fileExists(atPath: url.path) else { return nil }

    return url
  }

  static func gitRootUrl(base: URL) -> URL? {
    guard let path = shellCommandOutput("git rev-parse --show-toplevel", workingDirectory: base)
    else { return nil }

    return URL(fileURLWithPath: path, isDirectory: true)
  }

  private static func shellCommandOutput(_ command: String, workingDirectory: URL) -> String? {
    let task = Process()
    let pipe = Pipe()

    task.currentDirectoryURL = workingDirectory
    task.standardInput = nil
    task.standardOutput = pipe
    task.standardError = nil
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", command]

    do {
      try task.run()
      task.waitUntilExit()
    } catch {
      return nil
    }

    guard task.terminationStatus == 0 else { return nil }
    guard let output = String(
      data: pipe.fileHandleForReading.readDataToEndOfFile(),
      encoding: .utf8
    ) else { return nil }

    let result = output.trimmingCharacters(in: .whitespacesAndNewlines)
    if result.isEmpty { return nil } else { return result }
  }
}

private let fm = FileManager.default
