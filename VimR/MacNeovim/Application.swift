/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class Application: NSApplication {

  override init() {
    setPressAndHoldSetting()
    super.init()
  }

  required init?(coder: NSCoder) {
    setPressAndHoldSetting()
    super.init(coder: coder)
  }
}

fileprivate func setPressAndHoldSetting() {
  // disable default press and hold behavior (copied from MacVim)
  CFPreferencesSetAppValue(
    "ApplePressAndHoldEnabled" as NSString,
    "NO" as NSString,
    kCFPreferencesCurrentApplication
  )
}