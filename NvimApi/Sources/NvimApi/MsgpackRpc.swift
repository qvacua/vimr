/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack
import os

// Inspired by https://stackoverflow.com/a/76941591
extension Pipe {
  private struct DataReader {
    fileprivate let dataStream: AsyncStream<Data>

    init(pipe: Pipe) {
      self.dataStream = AsyncStream { continuation in
        pipe.fileHandleForReading.readabilityHandler = { handle in
          let data = handle.availableData

          if data.isEmpty {
            continuation.finish()
            return
          } else {
            continuation.yield(data)
          }

          continuation.onTermination = { _ in pipe.fileHandleForReading.readabilityHandler = nil }
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

    try await self.startReading()
  }

  public func stop() {
    self.log.debug("Stopping")
    self.cleanUp()
  }

  public func response(msgid: UInt32, error: Value, result: Value) throws {
    if self.closed {
      self.log.warning("Not sending response because closed")
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

    try self.inPipe?.fileHandleForWriting.write(contentsOf: packed)
  }

  public func request(
    method: String,
    params: [Value],
    expectsReturnValue: Bool
  ) async throws -> Response {
    if self.closed {
      self.log.warning("Not sending request because closed")
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

    let future = AsyncFuture<Response>()
    if expectsReturnValue { self.futures[msgid] = future }

    try self.inPipe?.fileHandleForWriting.write(contentsOf: packed)

    if !expectsReturnValue {
      return .nilResponse(msgid)
    }

    return try await future.value().get()
  }

  // MARK: Private

  private let log = Logger(subsystem: "com.qvacua.NvimApi", category: "rpc")

  private var closed = false

  private let streamContinuation: AsyncStream<Message>.Continuation

  private var inPipe: Pipe?
  private var outPipe: Pipe?
  private var errorPipe: Pipe?

  private var nextMsgid: UInt32 = 1
  private var futures = [UInt32: AsyncFuture<Response>]()

  private func startReading() async throws {
    Task.detached(priority: .high) {
      self.log.debug("Start reading")
      guard let dataStream = await self.outPipe?.asyncData else {
        throw Error(msg: "Could not get the async data stream")
      }

      var remainderData = Data()
      var dataToUnmarshall = Data()
      for await data in dataStream {
        do {
          if remainderData.count > 0 { dataToUnmarshall.append(remainderData) }
          dataToUnmarshall.append(data)

          let (values, remainder) = try self.unpackAllWithRemainder(dataToUnmarshall)

          dataToUnmarshall.removeAll(keepingCapacity: true)
          if let remainder { remainderData = remainder }
          else { remainderData.removeAll(keepingCapacity: true) }

          // Do we have to check closed here before processing the msgs?
          for value in values {
            await self.processMessage(value)
          }
        }
      }

      self.log.debug("End reading")
      await self.cleanUp()
    }
  }

  private func cleanUp() {
    if self.closed {
      self.log.info("MsgpackRpc already closed")
      return
    }

    self.log.debug("Cleaning up")
    self.closed = true

    self.inPipe = nil
    self.outPipe = nil
    self.errorPipe = nil

    self.streamContinuation.finish()
    for (msgid, future) in self.futures {
      future.yield(.success(.nilResponse(msgid)))
    }
    self.futures.removeAll()

    self.log.info("MsgpackRpc closed")
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
    guard let future = self.futures.removeValue(forKey: msgid) else { return }

    future.yield(.success(Response(msgid: msgid, error: error, result: result)))
  }

  private nonisolated func unpackAllWithRemainder(_ data: Data) throws
    -> (values: [Value], remainder: Data?)
  {
    var values = [Value]()
    var remainderData: Data?

    var subdata = Subdata(data: data)
    while !subdata.isEmpty {
      let value: Value
      do {
        (value, subdata) = try unpack(subdata, compatibility: false)
        values.append(consume value)
      } catch MessagePackError.insufficientData {
        remainderData = subdata.data
        break
      }
    }

    return (values, remainderData)
  }
}
