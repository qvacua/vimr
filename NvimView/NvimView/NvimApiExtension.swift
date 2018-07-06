/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxNeovimApi
import RxSwift

extension Api {

  public func bufGetInfo(
    buffer: Api.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, Api.Value>> {

    let params: [Api.Value] = [
      .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> Dictionary<String, Api.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw Api.Error.conversion(type: Dictionary<String, Api.Value>.self)
      }

      return result
    }

    if checkBlocked {
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

func msgPackDictToSwift(_ dict: Dictionary<Api.Value, Api.Value>?) -> Dictionary<String, Api.Value>? {
  return dict?.flatMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

private func msgPackArrayDictToSwift(_ array: [Api.Value]?) -> [Dictionary<String, Api.Value>]? {
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
