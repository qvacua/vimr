/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import MsgPackRpc

public class NvimApi {

  public struct Buffer: Equatable {

    public static func ==(lhs: Buffer, rhs: Buffer) -> Bool {
      return lhs.handle == rhs.handle
    }

    public let handle: Int

    public init(_ handle: Int) {
      self.handle = handle
    }
  }

  public struct Window: Equatable {

    public static func ==(lhs: Window, rhs: Window) -> Bool {
      return lhs.handle == rhs.handle
    }

    public let handle: Int

    public init(_ handle: Int) {
      self.handle = handle
    }
  }

  public struct Tabpage: Equatable {

    public static func ==(lhs: Tabpage, rhs: Tabpage) -> Bool {
      return lhs.handle == rhs.handle
    }

    public let handle: Int

    public init(_ handle: Int) {
      self.handle = handle
    }
  }

  public typealias Value = MsgPackRpc.Value
  public typealias Response<R> = Result<R, NvimApi.Error>
  public typealias NotificationCallback = Connection.NotificationCallback
  public typealias UnknownCallback = Connection.UnknownMessageCallback
  public typealias ErrorCallback = Connection.ErrorCallback

  public var notificationCallback: NotificationCallback? {
    get {
      return self.connection.notificationCallback
    }

    set {
      self.connection.notificationCallback = newValue
    }
  }

  public var unknownMessageCallback: UnknownCallback? {
    get {
      return self.connection.unknownMessageCallback
    }

    set {
      self.connection.unknownMessageCallback = newValue
    }
  }

  public var errorCallback: ErrorCallback? {
    get {
      return self.connection.errorCallback
    }

    set {
      self.connection.errorCallback = newValue
    }
  }

  public init?(at path: String) {
    guard let connection = MsgPackRpc.Connection(unixDomainSocketPath: path) else {
      return nil
    }

    self.connection = connection
  }

  public func connect() throws {
    try self.connection.run()
  }

  public func disconnect() {
    self.connection.stop()
  }

  @discardableResult
  public func checkBlocked<T>(_ fn: () -> NvimApi.Response<T>) -> NvimApi.Response<T> {
    guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
      return NvimApi.Response.failure(NvimApi.Error.blocked)
    }

    if blocked {
      return NvimApi.Response.failure(NvimApi.Error.blocked)
    }

    return fn()
  }

  public func rpc(method: String,
                  params: [MsgPackRpc.Value],
                  expectsReturnValue: Bool) -> NvimApi.Response<NvimApi.Value> {

    let msgid = locked(with: self.nextMsgidLock) { () -> UInt32 in
      let msgid = self.nextMsgid
      self.nextMsgid += 1
      return msgid
    }

    let response = self.connection.request(type: MessageType.request.rawValue,
                                           msgid: msgid,
                                           method: method,
                                           params: params,
                                           expectsReturnValue: expectsReturnValue)

    guard response.error.isNil else {
      print("\(response.error)")
      return .failure(NvimApi.Error(response.error))
    }

    return .success(response.result)
  }

  private let connection: Connection

  private var nextMsgid: UInt32 = 0
  private let nextMsgidLock = NSRecursiveLock()

  private var conditions: [UInt32: NSCondition] = [:]
  private let conditionsLock = NSRecursiveLock()

  @discardableResult
  private func locked<T>(with lock: NSLocking, fn: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return fn()
  }
}
