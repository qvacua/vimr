/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class ShellUtils {

  static let defaultPath = "/usr/local/bin:/opt/local/bin:/opt/bin:/usr/bin:/bin:/usr/sbin:/sbin"

  private static let cmdForPath = "env | grep '^PATH=' | sed 's/^PATH=//'"

  static func run(command command: String, arguments: [String] = []) -> String? {
    let pipe = NSPipe()

    let task = NSTask()
    task.standardOutput = pipe
    task.launchPath = command
    task.arguments = arguments

    task.launch()
    let file = pipe.fileHandleForReading;
    let data = file.readDataToEndOfFile()
    file.closeFile()

    let output = NSString(data: data, encoding: NSUTF8StringEncoding)
    return output?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
  }

  static func pathForUserShell() -> String {
    guard let shell = NSProcessInfo.processInfo().environment["SHELL"] else {
      return ShellUtils.defaultPath
    }

    let shellUrl = NSURL(fileURLWithPath: shell)
    guard let shellPath = shellUrl.path else {
      return ShellUtils.defaultPath
    }

    var shellOptions = [String]()
    if shellUrl.lastPathComponent != "tsch" {
      shellOptions.append("-l")
    }
    shellOptions.append("-c")
    shellOptions.append(ShellUtils.cmdForPath)

    return ShellUtils.run(command: shellPath, arguments: shellOptions) ?? ShellUtils.defaultPath
  }
}