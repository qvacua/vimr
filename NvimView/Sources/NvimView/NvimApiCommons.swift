/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxPack
import RxSwift

public extension RxNeovimApi {
  func getDirtyStatus(
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = []

    func transform(_ value: Value) throws -> Bool {
      guard let result = value.boolValue else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_dirty_status", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_dirty_status", params: params, expectsReturnValue: true)
      .map(transform)
  }

  func bufGetInfo(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [.int(Int64(buffer.handle))]

    func transform(_ value: Value) throws -> [String: RxNeovimApi.Value] {
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(self.rpc(method: "nvim_buf_get_info", params: params))
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_info", params: params)
      .map(transform)
  }
}

private func msgPackDictToSwift(
  _ dict: [RxNeovimApi.Value: RxNeovimApi.Value]?
) -> [String: RxNeovimApi.Value]? {
  dict?.flatMapToDict { k, v in
    guard let strKey = k.stringValue else { return nil }

    return (strKey, v)
  }
}

private func msgPackArrayDictToSwift(
  _ array: [RxNeovimApi.Value]?
) -> [[String: RxNeovimApi.Value]]? {
  array?
    .compactMap { v in v.dictionaryValue }
    .compactMap { d in msgPackDictToSwift(d) }
}

private extension Dictionary {
  func flatMapToDict<K, V>(
    _ transform: ((key: Key, value: Value)) throws -> (K, V)?
  ) rethrows -> [K: V] {
    let array = try self.compactMap(transform)
    return self.tuplesToDict(array)
  }

  func tuplesToDict<K: Hashable, V, S: Sequence>(
    _ sequence: S
  ) -> [K: V] where S.Iterator.Element == (K, V) {
    var result = [K: V](minimumCapacity: sequence.underestimatedCount)

    for (key, value) in sequence { result[key] = value }

    return result
  }
}
