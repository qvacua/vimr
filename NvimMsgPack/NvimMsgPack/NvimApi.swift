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
      return self.msgpackRpc.streamResponses
    }
    set {
      self.msgpackRpc.streamResponses = newValue
    }
  }

  public var streamRawResponses: Bool {
    get {
      return self.msgpackRpc.streamResponses
    }
    set {
      self.msgpackRpc.streamResponses = newValue
    }
  }

  public var msgpackRawStream: Observable<RxMsgpackRpc.Message> {
    return self.msgpackRpc.stream
  }

  public var queue = DispatchQueue(label: "com.qvacua.NvimMsgpack.NvimApi", qos: .userInitiated)

  public init() {
    self.msgpackRpc.queue = self.queue
  }

  public func run(at path: String) -> Completable {
    return self.msgpackRpc.run(at: path)
  }

  public func stop() -> Completable {
    return self.msgpackRpc.stop()
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

    return self.msgpackRpc
      .request(method: method, params: params, expectsReturnValue: expectsReturnValue)
      .map { response -> RxMsgpackRpc.Value in
        guard response.error.isNil else {
          throw NvimApi.Error(response.error)
        }

        return response.result
      }
  }

  private let msgpackRpc = MsgpackRpc()
}

fileprivate extension NSLocking {

  @discardableResult
  fileprivate func withLock<T>(_ body: () -> T) -> T {
    self.lock()
    defer { self.unlock() }
    return body()
  }
}
