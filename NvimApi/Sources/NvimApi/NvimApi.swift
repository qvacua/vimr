/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack

public actor NvimApi {
  public enum Event {
    case error(msg: String)
  }

  public struct Buffer: Equatable, Hashable, Sendable {
    public let handle: Int
    public init(_ handle: Int) { self.handle = handle }
  }

  public struct Window: Equatable, Hashable, Sendable {
    public let handle: Int
    public init(_ handle: Int) { self.handle = handle }
  }

  public struct Tabpage: Equatable, Hashable, Sendable {
    public let handle: Int
    public init(_ handle: Int) { self.handle = handle }
  }

  public typealias Value = MsgpackRpc.Value

  public var msgpackRawStream: AsyncStream<MsgpackRpc.Message> { self.msgpackRpc.messagesStream }

  public func run(inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe) async throws {
    try await self.msgpackRpc.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)
  }

  public func stop() async { await self.msgpackRpc.stop() }

  public func isBlocked() async -> Result<Bool, NvimApi.Error> {
    let modeResult = await self.nvimGetMode()
    switch modeResult {
    case let .success(dict):
      guard let value = dict["blocking"]?.boolValue else {
        return .failure(.conversion(type: Bool.self))
      }

      return .success(value)

    case let .failure(error):
      return .failure(error)
    }
  }

  public func sendRequest(
    method: String,
    params: [NvimApi.Value]
  ) async -> Result<Value, NvimApi.Error> {
    do {
      let reqResponse = try await self.msgpackRpc.request(
        method: method, params: params, expectsReturnValue: true
      )

      if reqResponse.isSuccess {
        return .success(reqResponse.result)
      } else {
        return .failure(.init(reqResponse.error))
      }
    } catch {
      return .failure(.other(cause: error))
    }
  }

  public func sendResponse(
    _ response: MsgpackRpc.Response
  ) async -> Result<Void, NvimApi.Error> {
    do {
      return try await .success(
        self.msgpackRpc.response(
          msgid: response.msgid, error: response.error, result: response.result
        )
      )
    } catch {
      return .failure(.other(cause: error))
    }
  }

  public init() {}

  func blockedError() async -> NvimApi.Error? {
    let blockedResult = await self.isBlocked()

    switch blockedResult {
    case let .success(blocked):
      if blocked { return .blocked }
    case let .failure(error):
      return .other(cause: error)
    }

    return nil
  }

  private let msgpackRpc = MsgpackRpc()
}