/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Sparkle

let fileLog = LogContext.fileLogger(as: "VimR-file", with: URL(fileURLWithPath: "/tmp/vimr.log"))
let stdoutLog = LogContext.stdoutLogger(as: "VimR-stdout")

class Application: NSApplication {

  override init() {
    setPressAndHoldSetting()
    super.init()
  }

  required init?(coder: NSCoder) {
    setPressAndHoldSetting()
    super.init(coder: coder)
  }

  @IBAction override func showHelp(_: Any?) {
    NSWorkspace.shared.open(URL(string: "https://github.com/qvacua/vimr/wiki")!)
  }
}

private func setPressAndHoldSetting() {
  // disable default press and hold behavior (copied from MacVim)
  CFPreferencesSetAppValue(
    "ApplePressAndHoldEnabled" as NSString,
    "NO" as NSString,
    kCFPreferencesCurrentApplication
  )
}
