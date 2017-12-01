/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import MsgPackRpc

public class Nvim {

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

  public struct Error: Swift.Error, CustomStringConvertible {

    public let type: ErrorType
    public let message: String

    public var description: String {
      return "\(Swift.type(of: self))(type: \(self.type), message: \"\(self.message)\")"
    }

    init(_ message: String) {
      self.type = .unknown
      self.message = message
    }

    public init(type: ErrorType, message: String) {
      self.type = type
      self.message = message
    }

    init(_ value: Nvim.Value?) {
      if let rawValue = value?.unsignedIntegerValue {
        self.type = ErrorType(rawValue: Int(rawValue)) ?? .unknown
      } else {
        self.type = .unknown
      }
      self.message = value?.arrayValue?[1].stringValue
                     ?? "ERROR: \(Error.self) could not be instantiated from \(String(describing: value))"
    }
  }

  public typealias Value = MsgPackRpc.Value

  public typealias Response<R> = Result<R, Nvim.Error>

  public var notificationCallback: ((MsgPackRpc.MessageType, String, [Nvim.Value]) -> Void)? {
    get {
      return self.session.notificationCallback
    }

    set {
      self.session.notificationCallback = newValue
    }
  }

  public var unknownMessageCallback: (([Nvim.Value]) -> Void)? {
    get {
      return self.session.unknownMessageCallback
    }

    set {
      self.session.unknownMessageCallback = newValue
    }
  }

  public var errorCallback: ((Nvim.Value) -> Void)? {
    get {
      return self.session.errorCallback
    }

    set {
      self.session.errorCallback = newValue
    }
  }

  public class Session {

    var notificationCallback: ((MsgPackRpc.MessageType, String, [Nvim.Value]) -> Void)? {
      get {
        return self.connection.notificationCallback
      }

      set {
        self.connection.notificationCallback = newValue
      }
    }

    var unknownMessageCallback: (([Nvim.Value]) -> Void)? {
      get {
        return self.connection.unknownMessageCallback
      }

      set {
        self.connection.unknownMessageCallback = newValue
      }
    }

    var errorCallback: ((Nvim.Value) -> Void)? {
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

    public func run() {
      self.connection.run()
    }

    public func stop() {
      self.connection.stop()
    }

    public func rpc(method: String,
             params: [MsgPackRpc.Value],
             expectsReturnValue: Bool) -> Result<MsgPackRpc.Value, Nvim.Error> {

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
        return .failure(Nvim.Error(response.error))
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

  public init?(at path: String) {
    guard let session = Session(at: path) else {
      return nil
    }

    self.session = session
  }

  public func connect() {
    self.session.run()
  }

  public func disconnect() {
    self.session.stop()
  }

  @discardableResult
  public func checkBlocked<T>(_ fn: () -> Nvim.Response<T>) -> Nvim.Response<T> {
    if self.getMode().value?.dictionaryValue?[.string("blocked")] == .bool(true) {
      return Nvim.Response.failure(Nvim.Error(type: .blocked, message: "Nvim is currently blocked."))
    }

    return fn()
  }

  public func rpc(method: String,
                params: [Nvim.Value],
                expectsReturnValue: Bool = true) -> Nvim.Response<Nvim.Value> {

    return self.session.rpc(method: method, params: params, expectsReturnValue: expectsReturnValue)
  }

  private let session: Session
}
