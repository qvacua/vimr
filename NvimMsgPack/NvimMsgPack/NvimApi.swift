/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxMsgpackRpc
import RxSwift

public class NvimApi {

  public enum Event {

    case error(msg: String)
  }

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

  public typealias Value = RxMsgpackRpc.Value

  public var streamResponses: Bool {
    get {
      return self.connection.streamResponses
    }
    set {
      self.connection.streamResponses = newValue
    }
  }

  public var streamRawResponses: Bool {
    get {
      return self.connection.streamResponses
    }
    set {
      self.connection.streamResponses = newValue
    }
  }

  public var msgpackRawStream: Observable<RxMsgpackRpc.Message> {
    return self.connection.stream
  }

  public init?(at path: String) {
    guard let connection = RxMsgpackRpc.Connection(unixDomainSocketPath: path) else {
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

  public func checkBlocked<T>(_ single: Single<T>) -> Single<T> {
    return self
      .getMode()
      .flatMap { dict -> Single<T> in
        guard (dict["blocking"]?.boolValue ?? false) == false else {
          throw NvimApi.Error.blocked
        }

        return single
      }
  }

  public func rpc(method: String,
                  params: [NvimApi.Value],
                  expectsReturnValue: Bool = true) -> Single<NvimApi.Value> {
    return self.connection
      .request(method: method, params: params, expectsReturnValue: expectsReturnValue)
      .map { response -> RxMsgpackRpc.Value in
        guard response.error.isNil else {
          throw NvimApi.Error(response.error)
        }

        return response.result
      }
  }

  private let connection: RxMsgpackRpc.Connection
}

fileprivate extension NSLocking {

  @discardableResult
  fileprivate func withLock<T>(_ body: () -> T) -> T {
    self.lock()
    defer { self.unlock() }
    return body()
  }
}
