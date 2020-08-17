//
//  AppDelegate.swift
//  EnvTest
//
//  Created by Tae Won Ha on 12.07.20.
//  Copyright © 2020 Tae Won Ha. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var textView: NSTextView!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
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
