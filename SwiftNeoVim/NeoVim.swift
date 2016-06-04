/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public class NeoVim {

  private static let qXpcName = "com.qvacua.nvox.xpc"

  private let xpcConnection: NSXPCConnection = NSXPCConnection(serviceName: NeoVim.qXpcName)

  private let neoVimUi: NeoVimUi = NeoVimUiImpl()

  private let xpc: NeoVimXpc

  public init() {
    self.xpcConnection.remoteObjectInterface = NSXPCInterface(withProtocol: NeoVimXpc.self)

    self.xpcConnection.exportedInterface = NSXPCInterface(withProtocol: NeoVimUi.self)
    self.xpcConnection.exportedObject = self.neoVimUi

    self.xpcConnection.resume()

    self.xpc = self.xpcConnection.remoteObjectProxy as! NeoVimXpc
  }

  deinit {
    self.xpcConnection.invalidate()
  }

  public func doSth() {
    self.xpc.doSth()
  }
}
