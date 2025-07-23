/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

// Hack
extension Document: @unchecked Sendable {}

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
    let docs = NSDocumentController.shared.documents.compactMap { $0 as? Document }

    Task {
      for d in docs {
        await d.quitWithoutSaving()
      }

      // Quit the app for real
      NSApplication.shared.reply(toApplicationShouldTerminate: true)
    }

    return .terminateLater
  }
}

private let openNewWindowWhenLaunching = true
