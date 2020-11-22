//
//  AppDelegate.swift
//  TabsSupport
//
//  Created by Tae Won Ha on 22.11.20.
//

import Cocoa
import Tabs

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var window: NSWindow!

  func applicationDidFinishLaunching(_: Notification) {
    // Insert code here to initialize your application
    Tabs()
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }
}
