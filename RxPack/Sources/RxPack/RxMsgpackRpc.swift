/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import MessagePack
import RxSwift
import Socket

public final class RxMsgpackRpc {
  public typealias Value = MessagePackValue

  enum MessageType: UInt64 {
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
  }

  public func run(at path: String) -> Completable {
    Completable.create { completable in
      self.queue.async {
        do {
          try self.socket = Socket.create(family: .unix, type: .stream, proto: .unix)
          try self.socket?.connect(to: path)
          self.setUpThreadAndStartReading()
        } catch {
          self.streamSubject.onError(Error(msg: "Could not get socket", cause: error))
          completable(.error(Error(msg: "Could not get socket at \(path)", cause: error)))
        }

        completable(.completed)
      }

      return Disposables.create()
    }
  }

  public func stop() -> Completable {
    Completable.create { completable in
      self.queue.async {
        self.cleanUpAndCloseSocket()
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

        if self.socket?.remoteConnectionClosed == true {
          single(.failure(Error(
            msg: "Connection stopped, but trying to send a request with msg id \(msgid)"
          )))
          return
        }

        guard let socket = self.socket else {
          single(.failure(Error(
            msg: "Socket is invalid, but trying to send a request with " +
              "msg id \(msgid): \(method) with \(params)"
          )))
          return
        }

        if expectsReturnValue { self.singles[msgid] = single }

        do {
          let writtenBytes = try socket.write(from: packed)
          if writtenBytes < packed.count {
            single(.failure(Error(
              msg: "(Written) = \(writtenBytes) < \(packed.count) = " +
                "(requested) for msg id: \(msgid)"
            )))

            return
          }
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

  private var socket: Socket?
  private var thread: Thread?
  private let queue: DispatchQueue

  private var singles: [UInt32: SingleResponseObserver] = [:]

  private let streamSubject = PublishSubject<Message>()

  private func nilResponse(with msgid: UInt32) -> Response {
    Response(msgid: msgid, error: .nil, result: .nil)
  }

  private func cleanUpAndCloseSocket() {
    self.streamSubject.onCompleted()

    self.singles.forEach { msgid, single in single(.success(self.nilResponse(with: msgid))) }
    self.singles.removeAll()

    self.socket?.close()
  }

  private func setUpThreadAndStartReading() {
    self.thread = Thread {
      guard let socket = self.socket else { return }

      var readData = Data(capacity: 10240)
      repeat {
        do {
          let readBytes = try socket.read(into: &readData)
          defer { readData.count = 0 }
          if readBytes > 0 {
            let values = try unpackAll(readData)
            values.forEach(self.processMessage)
          } else if readBytes == 0 {
            if socket.remoteConnectionClosed {
              self.queue.async { self.cleanUpAndCloseSocket() }
              return
            }

            continue
          }
        } catch let error as Socket.Error {
          self.streamSubject.onError(Error(msg: "Could not read from socket", cause: error))
          self.queue.async { self.cleanUpAndCloseSocket() }
          return
        } catch {
          self.streamSubject.onNext(
            .error(value: .nil, msg: "Data from socket could not be unpacked")
          )
          self.queue.async { self.cleanUpAndCloseSocket() }
          return
        }
      } while self.socket?.remoteConnectionClosed == false
    }

    self.thread?.start()
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
