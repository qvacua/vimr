//
// Created by Tae Won Ha on 08.12.17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import NvimMsgPack

extension NvimApi {

  public func getBufGetInfo(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Dictionary<String, NvimApi.Value>> {

    if checkBlocked && self.getMode().value?["blocking"]?.boolValue == true {
      return .failure(NvimApi.Error(type: .blocked, message: "Nvim is currently blocked"))
    }

    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]
    let response = self.rpc(method: "nvim_buf_get_info", params: params, expectsReturnValue: true)

    guard let value = response.value else {
      return .failure(response.error!)
    }

    guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
      return .failure(NvimApi.Error("Error converting result to \(Dictionary<String, NvimApi.Value>.self)"))
    }

    return .success(result)
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

fileprivate func msgPackArrayDictToSwift(_ array: [NvimApi.Value]?) -> [Dictionary<String, NvimApi.Value>]? {
  return array?
    .flatMap { v in v.dictionaryValue }
    .flatMap { d in msgPackDictToSwift(d) }
}

extension Dictionary {

  fileprivate func flatMapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)?) rethrows -> Dictionary<K, V> {
    let array = try self.flatMap(transform)
    return tuplesToDict(array)
  }

  fileprivate func tuplesToDict<K:Hashable, V, S:Sequence>(_ sequence: S)
      -> Dictionary<K, V> where S.Iterator.Element == (K, V) {

    var result = Dictionary<K, V>(minimumCapacity: sequence.underestimatedCount)

    for (key, value) in sequence {
      result[key] = value
    }

    return result
  }
}
