/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift
import RxPack

extension RxNeovimApi {

  public func getDirtyStatus(
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
    ]

    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
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

  public func bufGetInfo(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_info", params: params)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_info", params: params)
      .map(transform)
  }
}

private func msgPackDictToSwift(_ dict: Dictionary<RxNeovimApi.Value, RxNeovimApi.Value>?) -> Dictionary<String, RxNeovimApi.Value>? {
  return dict?.flatMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

private func msgPackArrayDictToSwift(_ array: [RxNeovimApi.Value]?) -> [Dictionary<String, RxNeovimApi.Value>]? {
  return array?
    .compactMap { v in v.dictionaryValue }
    .compactMap { d in msgPackDictToSwift(d) }
}

extension Dictionary {

  fileprivate func flatMapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)?) rethrows -> Dictionary<K, V> {
    let array = try self.compactMap(transform)
    return tuplesToDict(array)
  }

  fileprivate func tuplesToDict<K: Hashable, V, S: Sequence>(_ sequence: S)
      -> Dictionary<K, V> where S.Iterator.Element == (K, V) {

    var result = Dictionary<K, V>(minimumCapacity: sequence.underestimatedCount)

    for (key, value) in sequence {
      result[key] = value
    }

    return result
  }
}
