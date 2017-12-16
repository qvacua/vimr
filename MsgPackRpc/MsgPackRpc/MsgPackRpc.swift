/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public enum MessageType: UInt64 {

  case request = 0
  case response = 1
  case notification = 2
}

public typealias Value = MessagePackValue

public struct Response {

  public let type: MessageType
  public let msgid: UInt32
  public let error: Value
  public let result: Value
}

public class Connection {

  public typealias NotificationCallback = (MessageType, String, [Value]) -> Void
  public typealias ErrorCallback = (Value, String?) -> Void
  public typealias UnknownMessageCallback = ([Value]) -> Void

  public struct Error: Swift.Error {

    let message: String
  }

  public var timeout: Double {
    get { return self.session.timeout }
    set { self.session.timeout = newValue }
  }

  public var notificationCallback: NotificationCallback?
  public var unknownMessageCallback: UnknownMessageCallback?
  public var errorCallback: ErrorCallback?

  public init(with session: Session) {
    self.session = session

    session.dataCallback = { data in (try? unpackAll(data))?.forEach(self.processResponse) }
  }

  public convenience init?(unixDomainSocketPath path: String) {
    guard let session = UnixDomainSocketConnection(path: path) else {
      return nil
    }

    self.init(with: session)
  }

  public func run() throws {
    guard let error = self.session.connectAndRun() else {
      return
    }

    throw Error(message: error.localizedDescription)
  }

  public func stop() {
    self.stopped = true

    locked(with: self.sessionLock) {
      locked(with: self.conditionsLock) {
        self.conditions.values.forEach { condition in
          locked(with: condition) { condition.broadcast() }
        }
      }

      self.session.disconnectAndStop()
    }
  }

  @discardableResult
  public func request(type: UInt64 = MessageType.request.rawValue,
                      msgid: UInt32,
                      method: String,
                      params: [Value],
                      expectsReturnValue: Bool) -> MsgPackRpc.Response {

    let packed = pack(
      [
        .uint(UInt64(type)),
        .uint(UInt64(msgid)),
        .string(method),
        .array(params),
      ]
    )

    guard expectsReturnValue else {
      return locked(with: self.sessionLock) {
        if !self.stopped {
          self.session.write(packed)
        }

        return self.nilResponse(with: msgid)
      }
    }

    let condition = NSCondition()
    locked(with: self.conditionsLock) { self.conditions[msgid] = condition }

    locked(with: self.sessionLock) {
      if self.stopped {
        return
      }

      self.session.write(packed)
    }

    locked(with: condition) {
      while !self.stopped
            && self.responses[msgid] == nil
            && condition.wait(until: Date(timeIntervalSinceNow: self.session.timeout)) {}
    }
    locked(with: self.conditionsLock) { self.conditions.removeValue(forKey: msgid) }

    if self.stopped {
      return self.nilResponse(with: msgid)
    }

    let result = self.responses[msgid] ?? self.nilResponse(with: msgid)
    locked(with: self.responsesLock) { self.responses.removeValue(forKey: msgid) }

    return result
  }

  private let session: Session

  private var nextReqId: UInt32 = 0
  private let reqIdLock = NSRecursiveLock()

  private var responses: [UInt32: MsgPackRpc.Response] = [:]
  private var responsesLock = NSRecursiveLock()

  private var conditions: [UInt32: NSCondition] = [:]
  private let conditionsLock = NSRecursiveLock()

  private let sessionLock = NSRecursiveLock()
  private var stopped = false

  private func nilResponse(with msgid: UInt32) -> MsgPackRpc.Response {
    return MsgPackRpc.Response(type: .response, msgid: msgid, error: .nil, result: .nil)
  }

  private func processResponse(_ unpacked: Value) {
    guard let array = unpacked.arrayValue, let type = array[0].unsignedIntegerValue else {
      self.errorCallback?(unpacked, "Warning: Could not get the array or type.")
      return
    }

    switch type {

    case MessageType.response.rawValue:
      // response
      guard let msgid64 = array[1].unsignedIntegerValue else {
        self.errorCallback?(unpacked, "Warning: Could not get the request ID.")
        return
      }
      let msgid = UInt32(msgid64)

      guard let condition = locked(with: self.conditionsLock, fn: { self.conditions[msgid] }) else {
        return
      }

      let error = array[2]
      let result = array[3]

      locked(with: condition) {
        locked(with: self.responsesLock) {
          self.responses[msgid] = MsgPackRpc.Response(type: .response, msgid: msgid, error: error, result: result)
        }
        condition.broadcast()
      }

    case MessageType.notification.rawValue:
      // notification
      guard let method = array[1].stringValue, let params = array[2].arrayValue else {
        self.errorCallback?(unpacked, "Warning: Could not get the method and params.")
        return
      }

      self.notificationCallback?(.notification, method, params)

    default:
      // unknown
      self.unknownMessageCallback?(array)
    }
  }

  @discardableResult
  private func locked<T>(with lock: NSLocking, fn: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return fn()
  }
}

