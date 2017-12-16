/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import MsgPackRpc
import RxSwift

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
      return self.session.notificationCallback
    }

    set {
      self.session.notificationCallback = newValue
    }
  }

  public var unknownMessageCallback: UnknownCallback? {
    get {
      return self.session.unknownMessageCallback
    }

    set {
      self.session.unknownMessageCallback = newValue
    }
  }

  public var errorCallback: ErrorCallback? {
    get {
      return self.session.errorCallback
    }

    set {
      self.session.errorCallback = newValue
    }
  }

  public let stream: StreamApi

  public init?(at path: String) {
    guard let session = Session(at: path) else {
      return nil
    }

    self.session = session
    self.stream = StreamApi(session: session)
  }

  public func connect() throws {
    try self.session.run()
  }

  public func disconnect() {
    self.session.stop()
  }

  @discardableResult
  public func checkBlocked<T>(_ fn: () -> NvimApi.Response<T>) -> NvimApi.Response<T> {
    if self.getMode().value?["blocking"] == .bool(true) {
      return NvimApi.Response.failure(NvimApi.Error.blocked)
    }

    return fn()
  }

  public func rpc(method: String,
                  params: [NvimApi.Value],
                  expectsReturnValue: Bool = true) -> NvimApi.Response<NvimApi.Value> {

    return self.session.rpc(method: method, params: params, expectsReturnValue: expectsReturnValue)
  }

  private let session: Session
}

public class StreamApi {

  public var scheduler: SchedulerType?

  public func rpc(method: String, params: [NvimApi.Value], expectsReturnValue: Bool = true) -> Single<NvimApi.Value> {
    let single = Single<NvimApi.Value>.create { single in
      let response = self.session.rpc(method: method, params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()

      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }

      single(.success(value))
      return disposable
    }

    if let scheduler = self.scheduler {
      return single.subscribeOn(scheduler)
    }

    return single
  }

  init(session: Session) {
    self.session = session
  }

  let session: Session
}

class Session {

  var notificationCallback: NvimApi.NotificationCallback? {
    get {
      return self.connection.notificationCallback
    }

    set {
      self.connection.notificationCallback = newValue
    }
  }

  var unknownMessageCallback: NvimApi.UnknownCallback? {
    get {
      return self.connection.unknownMessageCallback
    }

    set {
      self.connection.unknownMessageCallback = newValue
    }
  }

  var errorCallback: NvimApi.ErrorCallback? {
    get {
      return self.connection.errorCallback
    }

    set {
      self.connection.errorCallback = newValue
    }
  }

  init?(at path: String) {
    guard let connection = MsgPackRpc.Connection(unixDomainSocketPath: path) else {
      return nil
    }

    self.connection = connection
  }

  func run() throws {
    try self.connection.run()
  }

  func stop() {
    self.connection.stop()
  }

  func rpc(method: String,
           params: [MsgPackRpc.Value],
           expectsReturnValue: Bool) -> Result<MsgPackRpc.Value, NvimApi.Error> {

    let msgid = locked(with: self.nextMsgidLock) { () -> UInt32 in
      let msgid = self.nextMsgid
      self.nextMsgid += 1
      return msgid
    }

    let response = self.connection.request(type: 0,
                                           msgid: msgid,
                                           method: method,
                                           params: params,
                                           expectsReturnValue: expectsReturnValue)

    guard response.error.isNil else {
      return .failure(NvimApi.Error(response.error))
    }

    return .success(response.result)
  }

  private let connection: MsgPackRpc.Connection

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
