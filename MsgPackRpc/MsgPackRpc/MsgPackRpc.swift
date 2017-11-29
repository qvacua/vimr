/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public enum MessageType: Int {

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

  public var notificationCallback: ((MessageType, String, [Value]) -> Void)?
  public var unknownMessageCallback: (([Value]) -> Void)?
  public var errorCallback: ((Value) -> Void)?

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

  public func run() {
    self.session.connectAndRun()
  }

  public func stop() {
    locked(with: self.conditionsLock) {
      self.conditions.values.forEach { condition in
        locked(with: condition) { condition.broadcast() }
      }
    }
    self.stopped = true
    self.session.disconnectAndStop()
  }

  @discardableResult
  public func request(type: Int = 0,
                      msgid: UInt32,
                      method: String,
                      params: [Value],
                      expectsReturnValue: Bool)
      -> MsgPackRpc.Response {

    let packed = pack(
      [
        .uint(UInt64(type)),
        .uint(UInt64(msgid)),
        .string(method),
        .array(params),
      ]
    )

    guard expectsReturnValue else {
      self.session.write(packed)
      return self.nilResponse(with: msgid)
    }

    let condition = NSCondition()
    locked(with: self.conditionsLock) { self.conditions[msgid] = condition }

    if self.stopped {
      return self.nilResponse(with: msgid)
    }

    self.session.write(packed)

    locked(with: condition) {
      while !self.stopped && self.responses[msgid] == nil && condition.wait(until: Date(timeIntervalSinceNow: 5)) {}
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

  private var stopped = false

  private func nilResponse(with msgid: UInt32) -> MsgPackRpc.Response {
    return MsgPackRpc.Response(type: .response, msgid: msgid, error: .nil, result: .nil)
  }

  private func processResponse(_ unpacked: Value) {
    guard let array = unpacked.arrayValue, let type = array[0].unsignedIntegerValue else {
      NSLog("Warning: could not get the array or type")
      self.errorCallback?(unpacked)
      return
    }

    switch type {

    case 1:
      // response
      guard let msgid64 = array[1].unsignedIntegerValue else {
        NSLog("Warning: could not get the request ID")
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

    case 2:
      // notification
      guard let method = array[1].stringValue else {
        return
      }

      guard let params = array[2].arrayValue else {
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

