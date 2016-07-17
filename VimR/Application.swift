/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class Application: NSApplication {

  override init() {
    super.init()

    // Do very early initializtion here

    // disable default press and hold behavior (copied from MacVim)
    CFPreferencesSetAppValue(
      "ApplePressAndHoldEnabled" as NSString,
      "NO" as NSString,
      kCFPreferencesCurrentApplication
    )
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
