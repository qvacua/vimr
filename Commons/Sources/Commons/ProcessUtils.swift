/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

public enum ProcessUtils {
  public static func loginShell() -> URL {
    URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/bash")
  }

  public static func execProcessViaLoginShell(
    cmd: String,
    cwd: URL,
    envs: [String: String],
    interactive: Bool,
    qos: QualityOfService
  ) -> Process? {
    let shellUrl = Self.loginShell()
    let shellName = shellUrl.lastPathComponent
    var shellArgs = [String]()
    if shellName != "tcsh" { shellArgs.append("-l") }
    if interactive { shellArgs.append("-i") }

    Self.logger.debug("Using \(shellUrl) with \(shellArgs)")

    let stdin = Pipe()
    let process = Process()
    process.environment = envs
    process.standardInput = stdin
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    process.currentDirectoryPath = cwd.path
    process.launchPath = shellUrl.path
    process.arguments = shellArgs
    process.qualityOfService = qos

    Self.logger.debug("Launched shell")
    do { try process.run() }
    catch { return nil }

    Self.logger.debug("exec \(cmd)")
    let cmd = "exec \(cmd)"
    guard let cmdData = cmd.data(using: .utf8) else { return nil }
    let writeHandle = stdin.fileHandleForWriting
    writeHandle.write(cmdData)
    writeHandle.closeFile()

    return process
  }

  public static func envVars(
    of shellPath: URL,
    usingInteractiveMode: Bool
  ) -> [String: String] {
    let shellName = shellPath.lastPathComponent
    var shellArgs = [String]()

    if shellName != "tcsh" {
      shellArgs.append("-l")
    }

    if usingInteractiveMode {
      shellArgs.append("-i")
    }

    let marker = UUID().uuidString
    shellArgs.append(contentsOf: ["-c", "echo \(marker) && env"])

    let outputPipe = Pipe()
    let errorPipe = Pipe()

    let process = Process()
    process.launchPath = shellPath.path
    process.arguments = shellArgs
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    process.currentDirectoryPath = NSHomeDirectory()
    process.launch()

    let readHandle = outputPipe.fileHandleForReading
    guard let output = String(
      data: readHandle.readDataToEndOfFile(), encoding: .utf8
    ) else {
      ProcessUtils.logger.error("No output; returning empty ENVs.")
      return [:]
    }
    readHandle.closeFile()

    process.terminate()
    process.waitUntilExit()

    guard let range = output.range(of: marker) else {
      ProcessUtils.logger.error("Marker not found; returning empty ENVs.")
      return [:]
    }

    return output[range.upperBound...]
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(separator: "\n")
      .reduce(into: [:]) { result, entry in
        let split = entry
          .split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
          .map { String($0) }
        guard split.count > 1 else { return }
        result[split[0]] = split[1]
      }
  }

  private static let logger = OSLog(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.general
  )
}
