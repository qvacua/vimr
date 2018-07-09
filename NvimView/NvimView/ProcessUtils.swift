/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class ProcessUtils {

  static func envVars(of shellPath: URL, usingInteractiveMode: Bool) -> [String: String] {
    let shellName = shellPath.lastPathComponent
    var shellArgs = [String]()

    if shellName != "tcsh" {
      shellArgs.append("-l")
    }

    if usingInteractiveMode {
      shellArgs.append("-i")
    }

    shellArgs.append(contentsOf: ["-c", "env"])

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
    guard let output = String(data: readHandle.readDataToEndOfFile(), encoding: .utf8) else {
      return [:]
    }
    readHandle.closeFile()

    process.terminate()
    process.waitUntilExit()

    return output
      .split(separator: "\n")
      .reduce(into: [:]) { result, entry in
        let split = entry.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map { String($0) }
        result[split[0]] = split[1]
      }
  }
}