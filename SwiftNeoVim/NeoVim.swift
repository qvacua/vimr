/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public class NeoVim {

  private static let qXpcName = "com.qvacua.nvox.xpc"

  private let xpcConnection: NSXPCConnection = NSXPCConnection(serviceName: NeoVim.qXpcName)
  
  public let xpc: NeoVimXpc
  public let view: NeoVimView

  public init() {
    self.xpcConnection.remoteObjectInterface = NSXPCInterface(withProtocol: NeoVimXpc.self)

    self.xpc = self.xpcConnection.remoteObjectProxy as! NeoVimXpc
    self.view = NeoVimView(xpc: self.xpc)
    
    self.xpcConnection.exportedInterface = NSXPCInterface(withProtocol: NeoVimUiBridgeProtocol.self)
    self.xpcConnection.exportedObject = self.view

    self.xpcConnection.resume()

    // bring the XPC service to life
    self.xpc.probe()
  }

  deinit {
    self.xpcConnection.invalidate()
  }
}
