//
// Created by Tae Won Ha on 08.12.17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import NvimMsgPack
import RxSwift

extension NvimApi {

  public func getBufGetInfo(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, NvimApi.Value>> {
    
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]
    
    func transform(_ value: Value) throws -> Dictionary<String, NvimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw NvimApi.Error.conversion(type: Dictionary<String, NvimApi.Value>.self)
      }
      
      return result
    }

    if checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_info", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_info", params: params, expectsReturnValue: true)
      .map(transform)
  }
}

func msgPackDictToSwift(_ dict: Dictionary<NvimApi.Value, NvimApi.Value>?) -> Dictionary<String, NvimApi.Value>? {
  return dict?.flatMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

private func msgPackArrayDictToSwift(_ array: [NvimApi.Value]?) -> [Dictionary<String, NvimApi.Value>]? {
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
