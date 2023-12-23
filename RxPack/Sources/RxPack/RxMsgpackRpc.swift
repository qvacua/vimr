/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack
import RxSwift
import os

public final class RxMsgpackRpc {
  public static let defaultReadBufferSize = 10240

  public typealias Value = MessagePackValue

  public enum MessageType: UInt64 {
    case request = 0
    case response = 1
    case notification = 2
  }

  public enum Message {
    case response(msgid: UInt32, error: Value, result: Value)
    case notification(method: String, params: [Value])
    case error(value: Value, msg: String)
    case request(msgid: UInt32, method: String, params: [Value])
  }

  public struct Response {
    public let msgid: UInt32
    public let error: Value
    public let result: Value
  }

  public struct Error: Swift.Error {
    var msg: String
    var cause: Swift.Error?

    init(msg: String, cause: Swift.Error? = nil) {
      self.msg = msg
      self.cause = cause
    }
  }

  /**
   Streams `Message.notification`s and `Message.error`s by default.
   When `streamResponses` is set to `true`, then also `Message.response`s.
   */
  public var stream: Observable<Message> { self.streamSubject.asObservable() }

  /**
   When `true`, all messages of type `MessageType.response` are also streamed
   to `stream` as `Message.response`. When `false`, only the `Single`s
   you get from `request(msgid, method, params, expectsReturnValue)` will
   get the response as `Response`.
   */
  public var streamResponses = false

  public let uuid = UUID()

  public init(queueQos: DispatchQoS) {
    let uuidStr = self.uuid.uuidString
    self.pipeReadQueue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-pipeReadQueue-\(uuidStr)",
      qos: queueQos
    )
    self.queue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-streamSubjectQueue-\(uuidStr)",
      qos: queueQos,
      target: .global(qos: queueQos.qosClass)
    )
  }

  public func run(inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe) {
    self.inPipe = inPipe
    self.outPipe = outPipe
    self.errorPipe = errorPipe

    self.startReading()
  }

  public func stop() {
    self.cleanUp()
  }

  public func response(msgid: UInt32, error: Value, result: Value) -> Completable {
    Completable.create { [weak self] completable in
      self?.queue.async {
        if self?.closed == true {
          self?.log.warning("Not sending response because closed")
          completable(.error(Error(msg: "Rpc closed")))
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

        do {
          try self?.inPipe?.fileHandleForWriting.write(contentsOf: packed)
          completable(.completed)
        } catch {
          self?.streamSubject.onError(Error(
            msg: "Could not write to socket for msg id: \(msgid)", cause: error
          ))

          completable(.error(Error(
            msg: "Could not write to socket for msg id: \(msgid)", cause: error
          )))

          return
        }
      }

      return Disposables.create()
    }
  }

  public func request(
    method: String,
    params: [Value],
    expectsReturnValue: Bool
  ) -> Single<Response> {
    Single.create { [weak self] single in
      self?.queue.async {
        if self?.closed == true {
          self?.log.warning("Not sending request because closed")
          single(.failure(Error(msg: "Rpc closed")))
          return
        }
        
        guard let msgid = self?.nextMsgid else { return }
        self?.nextMsgid += 1

        let packed = pack(
          [
            .uint(MessageType.request.rawValue),
            .uint(UInt64(msgid)),
            .string(method),
            .array(params),
          ]
        )

        if expectsReturnValue {
          // In streamQueue since we want to sync' access self.singles only in that queue.
          self?.queue.async { self?.singles[msgid] = single }
        }

        do {
          try self?.inPipe?.fileHandleForWriting.write(contentsOf: packed)
        } catch {
          self?.streamSubject.onError(Error(
            msg: "Could not write to socket for msg id: \(msgid)", cause: error
          ))

          single(.failure(Error(
            msg: "Could not write to socket for msg id: \(msgid)", cause: error
          )))

          return
        }

        if !expectsReturnValue {
          single(.success(Response(msgid: msgid, error: .nil, result: .nil)))
        }
      }

      return Disposables.create()
    }
  }

  // MARK: Private

  // R/w only in self.queue
  private var nextMsgid: UInt32 = 0
  private var closed = false

  private let pipeReadQueue: DispatchQueue
  private let queue: DispatchQueue

  private var inPipe: Pipe?
  private var outPipe: Pipe?
  private var errorPipe: Pipe?
  
  private let log = Logger(subsystem: "com.qvacua.RxPack.RxMsgpackRpc", category: "rpc")

  // R/w only in streamQueue
  private var singles: [UInt32: SingleResponseObserver] = [:]

  // Publish events only in streamQueue
  private let streamSubject = PublishSubject<Message>()

  private func nilResponse(with msgid: UInt32) -> Response {
    Response(msgid: msgid, error: .nil, result: .nil)
  }

  private func cleanUp() {
    self.queue.async { [weak self] in
      self?.closed = true
      
      self?.inPipe = nil
      self?.outPipe = nil
      self?.errorPipe = nil
      
      self?.streamSubject.onCompleted()
      self?.singles.forEach { _, single in single(.failure(Error(msg: "Rpc closed"))) }
      
      self?.log.info("RxMsgpackRpc closed")
    }
  }

  private func startReading() {
    self.pipeReadQueue.async { [weak self] in
      var dataToUnmarshall = Data(capacity: Self.defaultReadBufferSize)
      var bufferCount = 0
      while true {
        // If we do not use autoreleasepool here, the memory usage keeps going up
        autoreleasepool {
          guard let buffer = self?.outPipe?.fileHandleForReading.availableData,
                buffer.count > 0
          else {
            bufferCount = 0
            return
          }

          bufferCount = buffer.count
          dataToUnmarshall.append(buffer)
          _ = consume buffer
        }

        if bufferCount == 0 { break }

        do {
          guard let (values, remainderData) = try self?.unpackAllWithRemainder(dataToUnmarshall)
          else { throw Error(msg: "Nil when unpacking") }

          if let remainderData { dataToUnmarshall = remainderData }
          else { dataToUnmarshall.removeAll(keepingCapacity: true) }
          _ = consume remainderData

          self?.queue.async {
            if self?.closed == true {
              self?.log.info("Not processing msgs because closed.")
              return
            }
            values.forEach { value in self?.processMessage(value) }
          }
        } catch {
          self?.queue.async {
            self?.streamSubject.onError(Error(msg: "Could not read from pipe", cause: error))
          }
        }
      }

      self?.cleanUp()
    }
  }

  // Call only in self.streamQueue
  private func processMessage(_ unpacked: Value) {
    guard let array = unpacked.arrayValue else {
      self.streamSubject.onNext(.error(
        value: unpacked,
        msg: "Could not get the array from the message"
      ))
      return
    }

    guard let rawType = array[0].uint64Value, let type = MessageType(rawValue: rawType) else {
      self.streamSubject.onNext(.error(
        value: unpacked, msg: "Could not get the type of the message"
      ))
      return
    }

    switch type {
    case .response:
      guard array.count == 4 else {
        self.streamSubject.onNext(.error(
          value: unpacked,
          msg: "Got an array of length \(array.count) for a message type response"
        ))
        return
      }

      guard let msgid64 = array[1].uint64Value else {
        self.streamSubject.onNext(.error(value: unpacked, msg: "Could not get the msgid"))
        return
      }

      self.processResponse(msgid: UInt32(msgid64), error: array[2], result: array[3])

    case .notification:
      guard array.count == 3 else {
        self.streamSubject.onNext(.error(
          value: unpacked,
          msg: "Got an array of length \(array.count) for a message type notification"
        ))

        return
      }

      guard let method = array[1].stringValue, let params = array[2].arrayValue else {
        self.streamSubject.onNext(.error(
          value: unpacked,
          msg: "Could not get the method and params"
        ))
        return
      }

      self.streamSubject.onNext(.notification(method: method, params: params))

    case .request:
      guard let msgid = array[1].uint32Value, let method = array[2].stringValue,
            let params = array[3].arrayValue
      else { return }

      self.streamSubject.onNext(.request(msgid: msgid, method: method, params: params))
      return
    }
  }

  // Call only in self.streamQueue
  private func processResponse(msgid: UInt32, error: Value, result: Value) {
    if let single = self.singles.removeValue(forKey: msgid) {
      single(.success(Response(msgid: msgid, error: error, result: result)))
    }

    if self.streamResponses {
      self.streamSubject.onNext(.response(msgid: msgid, error: error, result: result))
    }
  }
}

// MARK: Private utilities

extension RxMsgpackRpc {
  private func unpackAllWithRemainder(_ data: Data) throws -> (values: [Value], remainder: Data?) {
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

private typealias SingleResponseObserver = (SingleEvent<RxMsgpackRpc.Response>) -> Void
