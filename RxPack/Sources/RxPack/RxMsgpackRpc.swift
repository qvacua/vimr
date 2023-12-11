/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack
import RxSwift
import Socket

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
    self.queue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-\(self.uuid.uuidString)",
      qos: queueQos,
      target: .global(qos: queueQos.qosClass)
    )
    self.dataQueue = DispatchQueue(
      label: "\(String(reflecting: RxMsgpackRpc.self))-dataQueue-\(self.uuid.uuidString)",
      qos: queueQos
    )
  }

  public func run( inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe) -> Completable {
    self.inPipe = inPipe
    self.outPipe = outPipe
    self.errorPipe = errorPipe
    
    return Completable.create { completable in
      self.queue.async {
        self.setUpThreadAndStartReading()
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

        if expectsReturnValue { self.singles[msgid] = single }

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
  private let dataQueue: DispatchQueue
  
  private var inPipe: Pipe?
  private var outPipe: Pipe?
  private var errorPipe: Pipe?

  private var singles: [UInt32: SingleResponseObserver] = [:]

  private let streamSubject = PublishSubject<Message>()

  private func nilResponse(with msgid: UInt32) -> Response {
    Response(msgid: msgid, error: .nil, result: .nil)
  }

  private func cleanUp() {
    self.inPipe = nil
    self.outPipe = nil
    self.errorPipe = nil
    
    self.streamSubject.onCompleted()

    self.singles.forEach { _, single in single(.failure(Error(msg: "Socket closed"))) }
  }

  private func setUpThreadAndStartReading() {
    self.dataQueue.async { [unowned self] in
      var readData: Data
      var dataToUnmarshall = Data(capacity: Self.defaultReadBufferSize)
      repeat {
        do {
          guard let buffer = self.outPipe?.fileHandleForReading.availableData else { break }
          readData = buffer

          if readData.count > 0 {
            dataToUnmarshall.append(readData)
            let (values, remainderData) = try RxMsgpackRpc.unpackAllWithReminder(dataToUnmarshall)
            if let remainderData { dataToUnmarshall = remainderData }
            else { dataToUnmarshall.count = 0 }

            values.forEach(self.processMessage)
          }
        } catch let error {
          self.streamSubject.onError(Error(msg: "Could not read from pipe", cause: error))
        }
      } while readData.count > 0
      
      self.streamSubject.onNext(.notification(method: "autocommand", params: ["exitpre"]))
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

      self.queue.async {
        self.processResponse(msgid: UInt32(msgid64), error: array[2], result: array[3])
      }

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
      self.streamSubject.onNext(.error(
        value: unpacked,
        msg: "Got message type request from remote"
      ))
      return
    }
  }

  public static func unpackAllWithReminder(_ data: Data) throws -> (values: [Value], remainder: Data?) {
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
