/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class Application: NSApplication {

  override init() {
    // Do very early initializtion here

    // disable default press and hold behavior (copied from MacVim)
    CFPreferencesSetAppValue(
      "ApplePressAndHoldEnabled" as NSString,
      "NO" as NSString,
      kCFPreferencesCurrentApplication
    )

    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction override func showHelp(_ sender: Any!) {
    NSWorkspace.shared().open(URL(string: "https://github.com/qvacua/vimr/wiki")!)
  }
}
