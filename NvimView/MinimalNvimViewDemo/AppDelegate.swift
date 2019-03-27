/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {}

  func applicationShouldTerminate(
    _: NSApplication
  ) -> NSApplication.TerminateReply {

    let docs = NSDocumentController.shared.documents
    if docs.isEmpty { return .terminateNow }

    try? Completable
      .concat(docs.compactMap { ($0 as? Document)?.quitWithoutSaving() })
      .wait()

    return .terminateNow
  }
}
