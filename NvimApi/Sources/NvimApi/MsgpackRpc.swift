/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack
import os
import Socket

// Inspired by https://stackoverflow.com/a/76941591
extension Pipe {
  private struct DataReader {
    fileprivate let dataStream: AsyncStream<Data>

    init(pipe: Pipe) {
      let (stream, cont) = AsyncStream<Data>.makeStream()
      self.dataStream = stream
      cont.onTermination = { [weak pipe] _ in pipe?.fileHandleForReading.readabilityHandler = nil }
      
      pipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData

        if data.isEmpty {
          cont.finish()
          return
        } else {
          cont.yield(data)
        }
      }
    }
  }

  var asyncData: AsyncStream<Data> { DataReader(pipe: self).dataStream }
}

public actor MsgpackRpc {
  public typealias Value = MessagePackValue

  public enum MessageType: UInt64 {
    case request = 0
    case response = 1
    case notification = 2
  }

  public enum Message: Sendable {
    case response(msgid: UInt32, error: Value, result: Value)
    case notification(method: String, params: [Value])
    case error(value: Value, msg: String)
    case request(msgid: UInt32, method: String, params: [Value])
  }

  public struct Response: Sendable {
    public static func nilResponse(_ msgid: UInt32) -> Self {
      .init(msgid: msgid, error: .nil, result: .nil)
    }

    public let msgid: UInt32
    public let error: Value
    public let result: Value

    public var isSuccess: Bool { self.error.isNil }
    public var isError: Bool { !self.isSuccess }
  }

  public struct Error: Swift.Error {
    var msg: String
    var cause: Swift.Error?

    init(msg: String, cause: Swift.Error? = nil) {
      self.msg = msg
      self.cause = cause
    }
  }

  public let messagesStream: AsyncStream<Message>

  public init() {
    (self.messagesStream, self.streamContinuation) = AsyncStream.makeStream()
  }

  public func run(inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe) async throws {
    self.inPipe = inPipe
    self.outPipe = outPipe
    self.errorPipe = errorPipe

    try await self.startReadingFromPipe()
  }

  /// Connect to an already-running neovim instance via a Unix domain socket
  /// (the path neovim was started with via `--listen`).
  public func run(socketPath: String) async throws {
    let sock = try Socket.create(family: .unix, proto: .unix)
    try sock.connect(to: socketPath)
    self.socket = sock
    try await self.startReadingFromSocket()
  }

  /// Connect to an already-running neovim instance via TCP (host:port).
  public func run(host: String, port: Int32) async throws {
    let sock = try Socket.create(family: .inet, type: .stream, proto: .tcp)
    try sock.connect(to: host, port: port)
    self.socket = sock
    try await self.startReadingFromSocket()
  }

  /// Connect to a neovim `--listen` address. Accepts either a Unix socket path
  /// (e.g. "/tmp/nvim.sock") or a TCP address (e.g. "localhost:6666").
  public func run(address: String) async throws {
    if let (host, port) = Self.parseTcpAddress(address) {
      try await self.run(host: host, port: port)
    } else {
      try await self.run(socketPath: address)
    }
  }

  /// Parses "host:port" into components. Returns nil if it's not a TCP address.
  nonisolated static func parseTcpAddress(_ address: String) -> (host: String, port: Int32)? {
    // URL needs a scheme to parse host/port correctly.
    guard let url = URL(string: "tcp://\(address)"),
          let host = url.host, !host.isEmpty,
          let port = url.port, (1...65535).contains(port)
    else { return nil }
    return (host, Int32(port))
  }

  public func stop() {
    dlog.debug("Stopping")
    self.cleanUp()
  }

  public func response(msgid: UInt32, error: Value, result: Value) throws {
    if self.closed {
      dlog.debug("Not sending response because closed")
      return
    }

    let packed = pack(
      [
        .uint(MessageType.response.rawValue),
        .uint(UInt64(msgid)),
        error,
        result,
      ]
    )

    try self.writeData(packed)
  }

  public func request(
    method: String,
    params: [Value],
    expectsReturnValue: Bool
  ) async throws -> Response {
    if self.closed {
      dlog.debug("Not sending request because closed")
      return .nilResponse(0)
    }

    let msgid = self.nextMsgid
    self.nextMsgid += 1

    let packed = pack(
      [
        .uint(MessageType.request.rawValue),
        .uint(UInt64(msgid)),
        .string(method),
        .array(params),
      ]
    )

    try self.writeData(packed)

    if !expectsReturnValue {
      return .nilResponse(msgid)
    }

    return await withCheckedContinuation { continuation in
      self.pendingRequests[msgid] = continuation
    }
  }

  // MARK: Private

  private let logger = Logger(subsystem: "com.qvacua.NvimApi", category: "rpc")

  private var closed = false

  private let streamContinuation: AsyncStream<Message>.Continuation

  private var inPipe: Pipe?
  private var outPipe: Pipe?
  private var errorPipe: Pipe?
  private var socket: Socket?

  private var readingTask: Task<Void, any Swift.Error>?

  private var nextMsgid: UInt32 = 1
  private var pendingRequests = [UInt32: CheckedContinuation<Response, Never>]()

  /// Unified write: sends data through whichever transport is active.
  private func writeData(_ data: Data) throws {
    if let socket = self.socket {
      try socket.write(from: data)
    } else if let pipe = self.inPipe {
      try pipe.fileHandleForWriting.write(contentsOf: data)
    } else {
      throw Error(msg: "No transport available for writing")
    }
  }

  private func startReadingFromPipe() async throws {
    self.readingTask = Task.detached(priority: .high) {
      dlog.debug("Start reading (pipe)")
      guard let dataStream = await self.outPipe?.asyncData else {
        throw Error(msg: "Could not get the async data stream")
      }

      var buffer = Data()
      for await data in dataStream {
        do {
          buffer.append(data)

          let (values, remainder) = try self.unpackAllWithRemainder(buffer)

          if let remainder {
            buffer = remainder
          } else {
            buffer.removeAll(keepingCapacity: true)
          }

          // Do we have to check closed here before processing the msgs?
          for value in values {
            await self.processMessage(value)
          }
        }
      }

      dlog.debug("End reading (pipe)")
      await self.cleanUp()
    }
  }

  private func startReadingFromSocket() async throws {
    guard let socket = self.socket else {
      throw Error(msg: "Socket not available for reading")
    }
    // Capture socket locally before entering the detached task to satisfy Sendable.
    // BlueSocket is not Sendable but we guarantee exclusive read access from this single task.
    nonisolated(unsafe) let sock = socket
    self.readingTask = Task.detached(priority: .high) {
      dlog.debug("Start reading (socket)")

      var buffer = Data()
      while !Task.isCancelled {
        var chunk = Data()
        let bytesRead: Int
        do {
          bytesRead = try sock.read(into: &chunk)
        } catch {
          if Task.isCancelled { break }
          throw Error(msg: "Socket read error", cause: error)
        }

        if bytesRead == 0 {
          // Connection closed by peer
          break
        }

        buffer.append(chunk)

        let (values, remainder) = try self.unpackAllWithRemainder(buffer)

        if let remainder {
          buffer = remainder
        } else {
          buffer.removeAll(keepingCapacity: true)
        }

        for value in values {
          await self.processMessage(value)
        }
      }

      dlog.debug("End reading (socket)")
      await self.cleanUp()
    }
  }

  private func cleanUp() {
    if self.closed {
      dlog.debug("MsgpackRpc already closed")
      return
    }

    dlog.debug("Cleaning up")
    self.closed = true

    self.readingTask?.cancel()
    self.readingTask = nil

    // Clean up pipe transport
    self.inPipe?.fileHandleForReading.readabilityHandler = nil
    self.inPipe?.fileHandleForWriting.closeFile()
    self.outPipe?.fileHandleForReading.closeFile()
    self.errorPipe?.fileHandleForReading.closeFile()

    self.inPipe = nil
    self.outPipe = nil
    self.errorPipe = nil

    // Clean up socket transport
    self.socket?.close()
    self.socket = nil

    self.streamContinuation.finish()
    for (msgid, continuation) in self.pendingRequests {
      continuation.resume(returning: .nilResponse(msgid))
    }
    self.pendingRequests.removeAll()

    dlog.debug("MsgpackRpc closed")
  }

  private func processMessage(_ unpacked: Value) {
    guard let array = unpacked.arrayValue else {
      self.streamContinuation.yield(with: .success(.error(
        value: unpacked,
        msg: "Could not get the array from the message"
      )))
      return
    }

    guard let rawType = array[0].uint64Value, let type = MessageType(rawValue: rawType) else {
      self.streamContinuation.yield(with: .success(.error(
        value: unpacked, msg: "Could not get the type of the message"
      )))
      return
    }

    switch type {
    case .response:
      guard array.count == 4 else {
        self.streamContinuation.yield(with: .success(.error(
          value: unpacked,
          msg: "Got an array of length \(array.count) for a message type response"
        )))
        return
      }

      guard let msgid64 = array[1].uint64Value else {
        self.streamContinuation.yield(with: .success(.error(
          value: unpacked, msg: "Could not get the msgid"
        )))
        return
      }

      self.processResponse(msgid: UInt32(msgid64), error: array[2], result: array[3])

    case .notification:
      guard array.count == 3 else {
        self.streamContinuation.yield(with: .success(.error(
          value: unpacked,
          msg: "Got an array of length \(array.count) for a message type notification"
        )))

        return
      }

      guard let method = array[1].stringValue, let params = array[2].arrayValue else {
        self.streamContinuation.yield(with: .success(.error(
          value: unpacked,
          msg: "Could not get the method and params"
        )))
        return
      }

      self.streamContinuation.yield(with: .success(.notification(
        method: method, params: params
      )))

    case .request:
      guard let msgid = array[1].uint32Value, let method = array[2].stringValue,
            let params = array[3].arrayValue
      else { return }

      self.streamContinuation.yield(with: .success(.request(
        msgid: msgid, method: method, params: params
      )))
      return
    }
  }

  private func processResponse(msgid: UInt32, error: Value, result: Value) {
    guard let continuation = self.pendingRequests.removeValue(forKey: msgid) else { return }

    continuation.resume(returning: Response(msgid: msgid, error: error, result: result))
  }

  private nonisolated func unpackAllWithRemainder(_ data: Data) throws
    -> (values: [Value], remainder: Data?)
  {
    var values = [Value]()
    var remainderData: Data?

    var subdata = data
    while !subdata.isEmpty {
      let value: Value
      do {
        (value, subdata) = try unpack(subdata, compatibility: false)
        values.append(consume value)
      } catch MessagePackError.insufficientData {
        remainderData = data
        break
      }
    }

    return (values, remainderData)
  }
}
