/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {}

  func applicationOpenUntitledFile(_: NSApplication) -> Bool {
    if openNewWindowWhenLaunching { false } else { true }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
    false
  }

  func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    NSDocumentController.shared
      .documents
      .compactMap { $0 as? Document }
      .forEach { $0.quitWithoutSaving() }

    return .terminateNow
  }
}

private let openNewWindowWhenLaunching = false
