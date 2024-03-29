/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var window: NSWindow!
  @IBOutlet var textView: NSTextView!

  func applicationDidFinishLaunching(_: Notification) {
    let selfEnv = ProcessInfo.processInfo.environment
    let shellUrl = URL(fileURLWithPath: selfEnv["SHELL"] ?? "/bin/bash")
    let env = ProcessUtils.envVars(of: shellUrl, usingInteractiveMode: false)

    for (k, v) in env {
      let str = NSAttributedString(string: "\(k): \(v)\n")
      print(str)
      self.textView.textStorage?.append(str)
    }
  }
}
