/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {}

  func applicationShouldTerminate(
    _: NSApplication
  ) -> NSApplication.TerminateReply {
    NSDocumentController.shared
      .documents
      .compactMap { $0 as? Document }
      .forEach { $0.quitWithoutSaving() }

    return .terminateNow
  }
}
