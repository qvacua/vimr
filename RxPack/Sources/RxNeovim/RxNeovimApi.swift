/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import RxPack
import RxSwift

public final class RxNeovimApi {
  public enum Event {
    case error(msg: String)
  }

  public struct Buffer: Equatable, Hashable {
    public let handle: Int
    public init(_ handle: Int) { self.handle = handle }
  }

  public struct Window: Equatable, Hashable {
    public let handle: Int
    public init(_ handle: Int) { self.handle = handle }
  }

  public struct Tabpage: Equatable, Hashable {
    public let handle: Int
    public init(_ handle: Int) { self.handle = handle }
  }

  public typealias Value = RxMsgpackRpc.Value

  public var msgpackRawStream: Observable<RxMsgpackRpc.Message> { self.msgpackRpc.stream }

  public func run(inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe) -> Completable {
    self.msgpackRpc.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)
  }

  public func stop() -> Completable { self.msgpackRpc.stop() }

  public func checkBlocked<T>(_ single: Single<T>) -> Single<T> {
    self
      .nvimGetMode()
      .flatMap { dict -> Single<T> in
        guard (dict["blocking"]?.boolValue ?? false) == false else {
          throw RxNeovimApi.Error.blocked
        }

        return single
      }
  }

  public func sendRequest(
    method: String,
    params: [RxNeovimApi.Value]
  ) -> Single<RxNeovimApi.Value> {
    self.msgpackRpc
      .request(method: method, params: params, expectsReturnValue: true)
      .map { response -> RxMsgpackRpc.Value in
        guard response.error.isNil else { throw RxNeovimApi.Error(response.error) }

        return response.result
      }
  }

  public func sendResponse(_ response: RxMsgpackRpc.Response) -> Completable {
    self.msgpackRpc.response(msgid: response.msgid, error: response.error, result: response.result)
  }

  public init() {}

  private let msgpackRpc = RxMsgpackRpc(queueQos: .userInteractive)
}
