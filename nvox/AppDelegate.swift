/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NeoVimViewDelegate, NeoVimXpcManagerProtocol {

  @IBOutlet weak var window: NSWindow!
  
  var neoVim: NeoVim!
  
  private let xpcConnection = NSXPCConnection(serviceName: "com.qvacua.nvox.xpc-match-maker")
  private var xpcMatchMaker: XpcMatchMakerProtocol!
  
  let serverUuid = NSUUID().UUIDString
  var neoVimUuid = NSUUID().UUIDString
  var task = NSTask()
  let executablePath = NSBundle.mainBundle().bundlePath + "/Contents/XPCServices/DummyXpc.xpc/Contents/MacOS/DummyXpc"

  @IBAction func debugSomething(sender: AnyObject!) {
//    NSLog("!!!!!!! launching: \(self.executablePath)")
    self.task.launchPath = self.executablePath
    self.task.arguments = [ self.serverUuid, self.neoVimUuid ]
    self.task.launch()

//    let font = NSFont(name: "Courier", size: 14)!
//    self.neoVim.view.setFont(font)
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.neoVim = NeoVim()
    self.neoVim.view.delegate = self

    let view = self.neoVim.view
    view.translatesAutoresizingMaskIntoConstraints = false
    self.window.contentView?.addSubview(self.neoVim.view)
    view.autoPinEdgesToSuperviewEdges()

    self.window.makeFirstResponder(self.neoVim.view)
    
    self.xpcConnection.remoteObjectInterface = NSXPCInterface(withProtocol: XpcMatchMakerProtocol.self)

    self.xpcMatchMaker = self.xpcConnection.remoteObjectProxy as! XpcMatchMakerProtocol
    
    self.xpcConnection.exportedInterface = NSXPCInterface(withProtocol: NeoVimXpcManagerProtocol.self)
    self.xpcConnection.exportedObject = self

    self.xpcConnection.resume()
    self.xpcMatchMaker.setServerUuid(serverUuid)
  }

  func shouldAcceptEndpoint(endpoint: NSXPCListenerEndpoint!, forNeoVimUuid neoVimUuid: String!) {
    NSLog("ACCEPT: \(neoVimUuid)")
  }

  func setTitle(title: String) {
    self.window.title = title
  }
  
  func applicationWillTerminate(notification: NSNotification) {
    self.task.terminate()
  }
}
