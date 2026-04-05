import Foundation
import MessagePack
import os
import Socket

/// Only supports requests
public class NvimApiSync: @unchecked Sendable {
  public init() {}

  public func run(socketPath: String) throws {
    let sock = try Socket.create(family: .unix, proto: .unix)
    try sock.connect(to: socketPath)
    self.socket = sock
  }

  public func run(host: String, port: Int32) throws {
    let sock = try Socket.create(family: .inet, type: .stream, proto: .tcp)
    try sock.connect(to: host, port: port)
    self.socket = sock
  }

  /// Connect to a neovim `--listen` address (Unix socket path or host:port).
  public func run(address: String) throws {
    if let (host, port) = MsgpackRpc.parseTcpAddress(address) {
      try self.run(host: host, port: port)
    } else {
      try self.run(socketPath: address)
    }
  }

  public func stop() {
    self.lock.lock()
    defer { lock.unlock() }
    self.socket?.close()
  }

  public func sendRequest(
    method: String,
    params: [MsgpackRpc.Value]
  ) -> Result<MsgpackRpc.Value, NvimApi.Error> {
    self.lock.lock()
    defer { lock.unlock() }

    self.msgId += 1

    let request: [MessagePackValue] = [
      .uint(MsgpackRpc.MessageType.request.rawValue),
      .uint(UInt64(self.msgId)),
      .string(method),
      .array(params),
    ]

    let data = MessagePack.pack(.array(request))

    do {
      guard let socket = self.socket else {
        return .failure(.exception(message: "NvimApiSync: not connected"))
      }
      try socket.write(from: data)

      var response = Data()
      _ = try socket.read(into: &response)

      let decoded = try MessagePack.unpack(response)
      guard case let .array(unpacked) = decoded.value,
            unpacked.count == 4,
            case .uint(MsgpackRpc.MessageType.response.rawValue) = unpacked[0]
      else { return .failure(.exception(message: "Invalid response")) }

      // Check for errors
      guard unpacked[2].isNil else { return .failure(.other(cause: NvimApi.Error(unpacked[2]))) }

      return .success(unpacked[3])
    } catch {
      return .failure(.other(cause: error))
    }
  }

  public func isBlocked() -> Result<Bool, NvimApi.Error> {
    let modeResult = self.nvimGetMode()
    switch modeResult {
    case let .success(dict):
      guard let value = dict["blocking"]?.boolValue else {
        return .failure(.conversion(type: Bool.self))
      }

      return .success(value)

    case let .failure(error):
      return .failure(error)
    }
  }

  func blockedError() -> NvimApi.Error? {
    let blockedResult = self.isBlocked()

    switch blockedResult {
    case let .success(blocked):
      if blocked { return .blocked }
    case let .failure(error):
      return .other(cause: error)
    }

    return nil
  }

  private var socket: Socket?
  private var msgId: UInt32 = 0
  private let lock = OSAllocatedUnfairLock()
}
