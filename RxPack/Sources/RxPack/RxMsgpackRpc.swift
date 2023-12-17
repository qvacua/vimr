/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack
import RxSwift

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
    self.queue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-\(uuidStr)",
      qos: queueQos,
      target: .global(qos: queueQos.qosClass)
    )
    self.pipeReadQueue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-pipeReadQueue-\(uuidStr)",
      qos: queueQos
    )
    self.streamQueue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-streamSubjectQueue-\(uuidStr)",
      qos: queueQos,
      target: .global(qos: queueQos.qosClass)
    )
  }

  public func run(inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe) -> Completable {
    self.inPipe = inPipe
    self.outPipe = outPipe
    self.errorPipe = errorPipe

    return Completable.create { completable in
      self.queue.async {
        self.startReading()
        completable(.completed)
      }

      return Disposables.create()
    }
  }

  public func stop() -> Completable {
    Completable.create { completable in
      self.queue.async {
        self.cleanUp()
        completable(.completed)
      }

      return Disposables.create()
    }
  }

  public func response(msgid: UInt32, error: Value, result: Value) -> Completable {
    Completable.create { completable in
      self.queue.async {
        let packed = pack(
          [
            .uint(MessageType.response.rawValue),
            .uint(UInt64(msgid)),
            error,
            result,
          ]
        )

        do {
          try self.inPipe?.fileHandleForWriting.write(contentsOf: packed)
          completable(.completed)
        } catch {
          self.streamSubject.onError(Error(
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
    Single.create { single in
      self.queue.async {
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

        if expectsReturnValue {
          self.streamQueue.async { self.singles[msgid] = single }
        }

        do {
          try self.inPipe?.fileHandleForWriting.write(contentsOf: packed)
        } catch {
          self.streamSubject.onError(Error(
            msg: "Could not write to socket for msg id: \(msgid)", cause: error
          ))

          single(.failure(Error(
            msg: "Could not write to socket for msg id: \(msgid)", cause: error
          )))

          return
        }

        if !expectsReturnValue { single(.success(self.nilResponse(with: msgid))) }
      }

      return Disposables.create()
    }
  }

  private var nextMsgid: UInt32 = 0

  private let queue: DispatchQueue
  private let pipeReadQueue: DispatchQueue
  private let streamQueue: DispatchQueue

  private var inPipe: Pipe?
  private var outPipe: Pipe?
  private var errorPipe: Pipe?

  // R/w only in streamQueue
  private var singles: [UInt32: SingleResponseObserver] = [:]

  // Publish events only in streamQueue
  private let streamSubject = PublishSubject<Message>()

  private func nilResponse(with msgid: UInt32) -> Response {
    Response(msgid: msgid, error: .nil, result: .nil)
  }

  private func cleanUp() {
    self.inPipe = nil
    self.outPipe = nil
    self.errorPipe = nil

    self.streamQueue.async {
      self.streamSubject.onCompleted()
      self.singles.forEach { _, single in single(.failure(Error(msg: "Pipe closed"))) }
    }
  }

  private func startReading() {
    self.pipeReadQueue.async { [unowned self] in
      var readData: Data
      var dataToUnmarshall = Data(capacity: Self.defaultReadBufferSize)
      repeat {
        do {
          guard let buffer = self.outPipe?.fileHandleForReading.availableData else { break }
          readData = buffer

          if readData.count > 0 {
            dataToUnmarshall.append(readData)
            let (values, remainderData) = try self.unpackAllWithReminder(dataToUnmarshall)
            if let remainderData { dataToUnmarshall = remainderData }
            else { dataToUnmarshall.count = 0 }

            self.streamQueue.async {
              values.forEach(self.processMessage)
            }
          }
        } catch {
          self.streamQueue.async {
            self.streamSubject.onError(Error(msg: "Could not read from pipe", cause: error))
          }
        }
      } while readData.count > 0

      self.cleanUp()
    }
  }

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

  private func unpackAllWithReminder(_ data: Data) throws -> (values: [Value], remainder: Data?) {
    var values = [Value]()
    var remainderData: Data?

    var data = Subdata(data: data)
    while !data.isEmpty {
      let value: Value
      do {
        (value, data) = try unpack(data, compatibility: false)
        values.append(value)
      } catch MessagePackError.insufficientData {
        remainderData = data.data
        break
      }
    }

    return (values, remainderData)
  }

  private func processResponse(msgid: UInt32, error: Value, result: Value) {
    if self.streamResponses {
      self.streamSubject.onNext(.response(msgid: msgid, error: error, result: result))
    }

    guard let single: SingleResponseObserver = self.singles[msgid] else { return }

    single(.success(Response(msgid: msgid, error: error, result: result)))
    self.singles.removeValue(forKey: msgid)
  }
}

private typealias SingleResponseObserver = (SingleEvent<RxMsgpackRpc.Response>) -> Void
