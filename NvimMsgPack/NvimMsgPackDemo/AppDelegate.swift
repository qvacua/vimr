//
//  AppDelegate.swift
//  NvimMsgPackDemo
//
//  Created by hat on 29.11.17.
//  Copyright © 2017 Tae Won Ha. All rights reserved.
//

import Cocoa
import NvimMsgPack

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  var nvim: Nvim?
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    guard let nvim = Nvim(at: "/tmp/nvim.sock") else {
      return
    }
    
    self.nvim = nvim
    nvim.connect()
    
    guard let curBuf = nvim.getCurrentBuf().value else {
      return
    }
    
    print(nvim.listBufs())
    print(nvim.bufGetChangedtick(buffer: curBuf))
    print(nvim.bufGetOption(buffer: curBuf, name: "mod"))
    print(nvim.bufGetName(buffer: curBuf))
    print(nvim.commandOutput(str: "echo expand(\"#3:p\")"))
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}

