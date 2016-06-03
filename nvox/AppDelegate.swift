/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  
  var xpcConnection: NSXPCConnection!
  
  var neoVimXpc: NeoVimXpc!

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    xpcConnection = NSXPCConnection(serviceName: "com.qvacua.nvox.xpc")
    xpcConnection.remoteObjectInterface = NSXPCInterface(withProtocol: NeoVimXpc.self)
    xpcConnection.resume()
    
    neoVimXpc = self.xpcConnection.remoteObjectProxy as! NeoVimXpc
    neoVimXpc.upperCaseString("Doing something from the main app...") { (result) in
      print(result)
    }
    
    neoVimXpc.doSth();
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    xpcConnection.invalidate()
  }
}

