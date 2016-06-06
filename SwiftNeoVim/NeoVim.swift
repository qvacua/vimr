/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public class NeoVim {
  
  enum UiEvent {
    case MoveCursor(position: Position)
    case Put(string: String)
    case Resize(size: Size)
  }
  
  struct Size {
    let rows: Int32
    let columns: Int32
  }
  
  struct Position {
    let row: Int32
    let column: Int32
  }

  enum ColorKind {
    case Foreground
    case Background
    case Special
  }

  private static let qXpcName = "com.qvacua.nvox.xpc"

  private let xpcConnection: NSXPCConnection = NSXPCConnection(serviceName: NeoVim.qXpcName)
  private let xpc: NeoVimXpc
  
  private let neoVimUiBridge: NeoVimUiBridge
  
  public let view: NeoVimView

  public init() {
    let neoVimUiBridge = NeoVimUiBridge()
    self.neoVimUiBridge = neoVimUiBridge
    
    self.xpcConnection.remoteObjectInterface = NSXPCInterface(withProtocol: NeoVimXpc.self)

    self.xpcConnection.exportedInterface = NSXPCInterface(withProtocol: NeoVimUiBridgeProtocol.self)
    self.xpcConnection.exportedObject = self.neoVimUiBridge

    self.xpcConnection.resume()

    self.xpc = self.xpcConnection.remoteObjectProxy as! NeoVimXpc
    self.view = NeoVimView(uiEventObservable: neoVimUiBridge.observable, xpc: self.xpc)
  }

  deinit {
    self.xpcConnection.invalidate()
  }

  public func vimInput(input: String) {
    self.xpc.vimInput(input)
  }
}
