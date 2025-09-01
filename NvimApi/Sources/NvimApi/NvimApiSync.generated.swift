// Auto generated for nvim version 0.11.3.
// See bin/generate_api_methods.py

import Foundation
import MessagePack

public extension NvimApiSync {
  func nvimGetAutocmds(
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_autocmds", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateAutocmd(
    event: NvimApi.Value,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      event,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_create_autocmd", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelAutocmd(
    id: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(id)),
    ]

    let reqResult = self.sendRequest(method: "nvim_del_autocmd", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimClearAutocmds(
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_clear_autocmds", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateAugroup(
    name: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_create_augroup", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelAugroupById(
    id: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(id)),
    ]

    let reqResult = self.sendRequest(method: "nvim_del_augroup_by_id", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelAugroupByName(
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_del_augroup_by_name", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimExecAutocmds(
    event: NvimApi.Value,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      event,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_exec_autocmds", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufLineCount(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_line_count", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufAttach(
    buffer: NvimApi.Buffer,
    send_buffer: Bool,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .bool(send_buffer),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_attach", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDetach(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_detach", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_lines", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_set_lines", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetText(
    buffer: NvimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    replacement: [String]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .array(replacement.map { .string($0) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_set_text", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetText(
    buffer: NvimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_text", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetOffset(
    buffer: NvimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_offset", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetVar(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetChangedtick(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_changedtick", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetKeymap(
    buffer: NvimApi.Buffer,
    mode: String,
    errWhenBlocked: Bool = true
  ) -> Result<[[String: NvimApi.Value]], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [[String: NvimApi.Value]] in
      guard let result = msgPackArrayDictToSwift(value.arrayValue) else {
        throw NvimApi.Error.conversion(type: [[String: NvimApi.Value]].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_keymap", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [[String: NvimApi.Value]] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetKeymap(
    buffer: NvimApi.Buffer,
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_set_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelKeymap(
    buffer: NvimApi.Buffer,
    mode: String,
    lhs: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_del_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetVar(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelVar(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetName(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetName(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_set_name", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufIsLoaded(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_is_loaded", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelete(
    buffer: NvimApi.Buffer,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_delete", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufIsValid(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelMark(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_del_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetMark(
    buffer: NvimApi.Buffer,
    name: String,
    line: Int,
    col: Int,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      .int(Int64(line)),
      .int(Int64(col)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_set_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetMark(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufCall(
    buffer: NvimApi.Buffer,
    fun: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      fun,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_call", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimParseCmd(
    str: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_parse_cmd", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCmd(
    cmd: [String: NvimApi.Value],
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(cmd.mapToDict { (NvimApi.Value.string($0), $1) }),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_cmd", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateUserCommand(
    name: String,
    command: NvimApi.Value,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      command,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_create_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelUserCommand(
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_del_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufCreateUserCommand(
    buffer: NvimApi.Buffer,
    name: String,
    command: NvimApi.Value,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      command,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_create_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelUserCommand(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_del_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCommands(
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_commands", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetCommands(
    buffer: NvimApi.Buffer,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_commands", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimExec(
    src: String,
    output: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(src),
      .bool(output),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_exec", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimCommandOutput(
    command: String,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(command),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_command_output", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimExecuteLua(
    code: String,
    args: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(code),
      args,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_execute_lua", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufGetNumber(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufClearHighlight(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_clear_highlight", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufAddHighlight(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .string(hl_group),
      .int(Int64(line)),
      .int(Int64(col_start)),
      .int(Int64(col_end)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_add_highlight", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufSetVirtualText(
    buffer: NvimApi.Buffer,
    src_id: Int,
    line: Int,
    chunks: NvimApi.Value,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(src_id)),
      .int(Int64(line)),
      chunks,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_set_virtual_text", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetHlById(
    hl_id: Int,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(hl_id)),
      .bool(rgb),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_hl_by_id", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetHlByName(
    name: String,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .bool(rgb),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_hl_by_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferInsert(
    buffer: NvimApi.Buffer,
    lnum: Int,
    lines: [String]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(lnum)),
      .array(lines.map { .string($0) }),
    ]

    let reqResult = self.sendRequest(method: "buffer_insert", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLine(
    buffer: NvimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_line", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLine(
    buffer: NvimApi.Buffer,
    index: Int,
    line: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
      .string(line),
    ]

    let reqResult = self.sendRequest(method: "buffer_set_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferDelLine(
    buffer: NvimApi.Buffer,
    index: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let reqResult = self.sendRequest(method: "buffer_del_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLineSlice(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_line_slice", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLineSlice(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    replacement: [String]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
      .array(replacement.map { .string($0) }),
    ]

    let reqResult = self.sendRequest(method: "buffer_set_line_slice", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetVar(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferDelVar(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetVar(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowDelVar(
    window: NvimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageSetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    value: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "tabpage_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageDelVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "tabpage_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetVar(
    name: String,
    value: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimDelVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetOptionInfo(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_option_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimSetOption(
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufGetOption(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufSetOption(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimWinGetOption(
    window: NvimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimWinSetOption(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimCallAtomic(
    calls: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      calls,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_call_atomic", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimSubscribe(
    event: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(event),
    ]

    let reqResult = self.sendRequest(method: "nvim_subscribe", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimUnsubscribe(
    event: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(event),
    ]

    let reqResult = self.sendRequest(method: "nvim_unsubscribe", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimOutWrite(
    str: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
    ]

    let reqResult = self.sendRequest(method: "nvim_out_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimErrWrite(
    str: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
    ]

    let reqResult = self.sendRequest(method: "nvim_err_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimErrWriteln(
    str: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
    ]

    let reqResult = self.sendRequest(method: "nvim_err_writeln", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimNotify(
    msg: String,
    log_level: Int,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(msg),
      .int(Int64(log_level)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_notify", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateNamespace(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_create_namespace", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetNamespaces(
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_namespaces", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetExtmarkById(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    id: Int,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(id)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_extmark_by_id", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetExtmarks(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    start: NvimApi.Value,
    end: NvimApi.Value,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      start,
      end,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_get_extmarks", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetExtmark(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    line: Int,
    col: Int,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line)),
      .int(Int64(col)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_set_extmark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelExtmark(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    id: Int,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(id)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_buf_del_extmark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufClearNamespace(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    let reqResult = self.sendRequest(method: "nvim_buf_clear_namespace", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetDecorationProvider(
    ns_id: Int,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_decoration_provider", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetOptionValue(
    name: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_option_value", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetOptionValue(
    name: String,
    value: NvimApi.Value,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_option_value", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetAllOptionsInfo(
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_all_options_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetOptionInfo2(
    name: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_option_info2", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageListWins(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Window], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Window(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_tabpage_list_wins", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageGetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_tabpage_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageSetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_tabpage_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageDelVar(
    tabpage: NvimApi.Tabpage,
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_tabpage_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageGetWin(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Window, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Window in
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_tabpage_get_win", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageSetWin(
    tabpage: NvimApi.Tabpage,
    win: NvimApi.Window
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .int(Int64(win.handle)),
    ]

    let reqResult = self.sendRequest(method: "nvim_tabpage_set_win", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageGetNumber(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_tabpage_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageIsValid(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_tabpage_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiAttach(
    width: Int,
    height: Int,
    options: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .map(options.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_attach", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiAttach(
    width: Int,
    height: Int,
    enable_rgb: Bool
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .bool(enable_rgb),
    ]

    let reqResult = self.sendRequest(method: "ui_attach", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiSetFocus(
    gained: Bool
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .bool(gained),
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_set_focus", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiDetach(
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_detach", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiTryResize(
    width: Int,
    height: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_try_resize", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiSetOption(
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiTryResizeGrid(
    grid: Int,
    width: Int,
    height: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(grid)),
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_try_resize_grid", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiPumSetHeight(
    height: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(height)),
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_pum_set_height", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiPumSetBounds(
    width: Float,
    height: Float,
    row: Float,
    col: Float
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .float(width),
      .float(height),
      .float(row),
      .float(col),
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_pum_set_bounds", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiTermEvent(
    event: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(event),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_ui_term_event", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetHlIdByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_hl_id_by_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetHl(
    ns_id: Int,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_hl", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetHl(
    ns_id: Int,
    name: String,
    val: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(ns_id)),
      .string(name),
      .map(val.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_hl", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetHlNs(
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_hl_ns", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetHlNs(
    ns_id: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_hl_ns", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetHlNsFast(
    ns_id: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_hl_ns_fast", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimFeedkeys(
    keys: String,
    mode: String,
    escape_ks: Bool
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    let reqResult = self.sendRequest(method: "nvim_feedkeys", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimInput(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(keys),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_input", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimInputMouse(
    button: String,
    action: String,
    modifier: String,
    grid: Int,
    row: Int,
    col: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(button),
      .string(action),
      .string(modifier),
      .int(Int64(grid)),
      .int(Int64(row)),
      .int(Int64(col)),
    ]

    let reqResult = self.sendRequest(method: "nvim_input_mouse", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimReplaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
      .bool(from_part),
      .bool(do_lt),
      .bool(special),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_replace_termcodes", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimExecLua(
    code: String,
    args: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(code),
      args,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_exec_lua", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimStrwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(text),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_strwidth", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_list_runtime_paths", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetRuntimeFile(
    name: String,
    all: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .bool(all),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_runtime_file", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentDir(
    dir: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(dir),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_current_dir", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentLine(
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_current_line", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentLine(
    line: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(line),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_current_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelCurrentLine(
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let reqResult = self.sendRequest(method: "nvim_del_current_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetVar(
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelVar(
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_vvar", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetVvar(
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_set_vvar", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimEcho(
    chunks: NvimApi.Value,
    history: Bool,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      chunks,
      .bool(history),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_echo", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListBufs(
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Buffer], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Buffer(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_list_bufs", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Buffer] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentBuf(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Buffer, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Buffer in
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_current_buf", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentBuf(
    buffer: NvimApi.Buffer
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_current_buf", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListWins(
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Window], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Window(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_list_wins", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentWin(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Window, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Window in
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_current_win", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentWin(
    window: NvimApi.Window
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_current_win", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateBuf(
    listed: Bool,
    scratch: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Buffer, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .bool(listed),
      .bool(scratch),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Buffer in
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_create_buf", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimOpenTerm(
    buffer: NvimApi.Buffer,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_open_term", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimChanSend(
    chan: Int,
    data: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(chan)),
      .string(data),
    ]

    let reqResult = self.sendRequest(method: "nvim_chan_send", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListTabpages(
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Tabpage], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Tabpage(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_list_tabpages", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Tabpage] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentTabpage(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Tabpage, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Tabpage in
      guard let result = (NvimApi.Tabpage(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_current_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentTabpage(
    tabpage: NvimApi.Tabpage
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_current_tabpage", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimPaste(
    data: String,
    crlf: Bool,
    phase: Int,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(data),
      .bool(crlf),
      .int(Int64(phase)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_paste", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimPut(
    lines: [String],
    type: String,
    after: Bool,
    follow: Bool
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .array(lines.map { .string($0) }),
      .string(type),
      .bool(after),
      .bool(follow),
    ]

    let reqResult = self.sendRequest(method: "nvim_put", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetColorByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_color_by_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetColorMap(
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_color_map", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetContext(
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_context", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimLoadContext(
    dict: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .map(dict.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_load_context", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetMode(
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let reqResult = self.sendRequest(method: "nvim_get_mode", params: params)
    switch reqResult {
    case let .success(value):
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        return .failure(NvimApi.Error.conversion(type: [String: NvimApi.Value].self))
      }
      return .success(result)

    case let .failure(error):
      return .failure(error)
    }
  }

  func nvimGetKeymap(
    mode: String,
    errWhenBlocked: Bool = true
  ) -> Result<[[String: NvimApi.Value]], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(mode),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [[String: NvimApi.Value]] in
      guard let result = msgPackArrayDictToSwift(value.arrayValue) else {
        throw NvimApi.Error.conversion(type: [[String: NvimApi.Value]].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_keymap", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [[String: NvimApi.Value]] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetKeymap(
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelKeymap(
    mode: String,
    lhs: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(mode),
      .string(lhs),
    ]

    let reqResult = self.sendRequest(method: "nvim_del_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetApiInfo(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_api_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetClientInfo(
    name: String,
    version: [String: NvimApi.Value],
    type: String,
    methods: [String: NvimApi.Value],
    attributes: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .map(version.mapToDict { (NvimApi.Value.string($0), $1) }),
      .string(type),
      .map(methods.mapToDict { (NvimApi.Value.string($0), $1) }),
      .map(attributes.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_set_client_info", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetChanInfo(
    chan: Int,
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(chan)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_chan_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListChans(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_list_chans", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListUis(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_list_uis", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetProcChildren(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(pid)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_proc_children", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetProc(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(pid)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_proc", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSelectPopupmenuItem(
    item: Int,
    insert: Bool,
    finish: Bool,
    opts: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(item)),
      .bool(insert),
      .bool(finish),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_select_popupmenu_item", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelMark(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_del_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetMark(
    name: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_get_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimEvalStatusline(
    str: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_eval_statusline", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimExec2(
    src: String,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(src),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_exec2", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCommand(
    command: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(command),
    ]

    let reqResult = self.sendRequest(method: "nvim_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimEval(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(expr),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_eval", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCallFunction(
    fn: String,
    args: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(fn),
      args,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_call_function", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCallDictFunction(
    dict: NvimApi.Value,
    fn: String,
    args: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      dict,
      .string(fn),
      args,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_call_dict_function", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimParseExpression(
    expr: String,
    flags: String,
    highlight: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(expr),
      .string(flags),
      .bool(highlight),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_parse_expression", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimOpenWin(
    buffer: NvimApi.Buffer,
    enter: Bool,
    config: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Window, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .bool(enter),
      .map(config.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Window in
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_open_win", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetConfig(
    window: NvimApi.Window,
    config: [String: NvimApi.Value]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .map(config.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_config", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetConfig(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_config", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetBuf(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Buffer, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Buffer in
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_buf", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetBuf(
    window: NvimApi.Window,
    buffer: NvimApi.Buffer
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(buffer.handle)),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_buf", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetCursor(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_cursor", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetCursor(
    window: NvimApi.Window,
    pos: [Int]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_cursor", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetHeight(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_height", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetHeight(
    window: NvimApi.Window,
    height: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_height", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetWidth(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_width", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetWidth(
    window: NvimApi.Window,
    width: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_width", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetVar(
    window: NvimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetVar(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinDelVar(
    window: NvimApi.Window,
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetPosition(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_position", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetTabpage(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Tabpage, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Tabpage in
      guard let result = (NvimApi.Tabpage(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetNumber(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinIsValid(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinHide(
    window: NvimApi.Window
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_hide", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinClose(
    window: NvimApi.Window,
    force: Bool
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .bool(force),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_close", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinCall(
    window: NvimApi.Window,
    fun: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      fun,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_call", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetHlNs(
    window: NvimApi.Window,
    ns_id: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(ns_id)),
    ]

    let reqResult = self.sendRequest(method: "nvim_win_set_hl_ns", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinTextHeight(
    window: NvimApi.Window,
    opts: [String: NvimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .map(opts.mapToDict { (NvimApi.Value.string($0), $1) }),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "nvim_win_text_height", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferLineCount(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_line_count", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_lines", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    let reqResult = self.sendRequest(method: "buffer_set_lines", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetVar(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetName(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetName(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let reqResult = self.sendRequest(method: "buffer_set_name", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferIsValid(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetMark(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCommandOutput(
    command: String,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(command),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_command_output", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetNumber(
    buffer: NvimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferClearHighlight(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    let reqResult = self.sendRequest(method: "buffer_clear_highlight", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferAddHighlight(
    buffer: NvimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .string(hl_group),
      .int(Int64(line)),
      .int(Int64(col_start)),
      .int(Int64(col_end)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_add_highlight", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetOption(
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "vim_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetOption(
    buffer: NvimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "buffer_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetOption(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "buffer_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetOption(
    window: NvimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetOption(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    let reqResult = self.sendRequest(method: "window_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSubscribe(
    event: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(event),
    ]

    let reqResult = self.sendRequest(method: "vim_subscribe", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimUnsubscribe(
    event: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(event),
    ]

    let reqResult = self.sendRequest(method: "vim_unsubscribe", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimOutWrite(
    str: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
    ]

    let reqResult = self.sendRequest(method: "vim_out_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimErrWrite(
    str: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
    ]

    let reqResult = self.sendRequest(method: "vim_err_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimReportError(
    str: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
    ]

    let reqResult = self.sendRequest(method: "vim_report_error", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetWindows(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Window], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Window(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "tabpage_get_windows", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "tabpage_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetWindow(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Window, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Window in
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "tabpage_get_window", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageIsValid(
    tabpage: NvimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "tabpage_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiDetach(
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let reqResult = self.sendRequest(method: "ui_detach", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiTryResize(
    width: Int,
    height: Int,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "ui_try_resize", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimFeedkeys(
    keys: String,
    mode: String,
    escape_ks: Bool
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    let reqResult = self.sendRequest(method: "vim_feedkeys", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimInput(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(keys),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_input", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimReplaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(str),
      .bool(from_part),
      .bool(do_lt),
      .bool(special),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_replace_termcodes", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimStrwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(text),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_strwidth", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimListRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Result<[String], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NvimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_list_runtime_paths", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimChangeDirectory(
    dir: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(dir),
    ]

    let reqResult = self.sendRequest(method: "vim_change_directory", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentLine(
    errWhenBlocked: Bool = true
  ) -> Result<String, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_current_line", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentLine(
    line: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(line),
    ]

    let reqResult = self.sendRequest(method: "vim_set_current_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimDelCurrentLine(
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let reqResult = self.sendRequest(method: "vim_del_current_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_vvar", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetBuffers(
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Buffer], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Buffer(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_buffers", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Buffer] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentBuffer(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Buffer, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Buffer in
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_current_buffer", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentBuffer(
    buffer: NvimApi.Buffer
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let reqResult = self.sendRequest(method: "vim_set_current_buffer", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetWindows(
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Window], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Window(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_windows", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentWindow(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Window, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Window in
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_current_window", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentWindow(
    window: NvimApi.Window
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let reqResult = self.sendRequest(method: "vim_set_current_window", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetTabpages(
    errWhenBlocked: Bool = true
  ) -> Result<[NvimApi.Tabpage], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [NvimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in NvimApi.Tabpage(v) }) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_tabpages", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [NvimApi.Tabpage] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentTabpage(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Tabpage, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Tabpage in
      guard let result = (NvimApi.Tabpage(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_current_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentTabpage(
    tabpage: NvimApi.Tabpage
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let reqResult = self.sendRequest(method: "vim_set_current_tabpage", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimNameToColor(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_name_to_color", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetColorMap(
    errWhenBlocked: Bool = true
  ) -> Result<[String: NvimApi.Value], NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [String: NvimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw NvimApi.Error.conversion(type: [String: NvimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_color_map", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [String: NvimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetApiInfo(
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_get_api_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCommand(
    command: String
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(command),
    ]

    let reqResult = self.sendRequest(method: "vim_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimEval(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(expr),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_eval", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCallFunction(
    fn: String,
    args: NvimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .string(fn),
      args,
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "vim_call_function", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetBuffer(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Buffer, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Buffer in
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_buffer", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetCursor(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_cursor", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetCursor(
    window: NvimApi.Window,
    pos: [Int]
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    let reqResult = self.sendRequest(method: "window_set_cursor", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetHeight(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_height", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetHeight(
    window: NvimApi.Window,
    height: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    let reqResult = self.sendRequest(method: "window_set_height", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetWidth(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Int, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NvimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_width", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetWidth(
    window: NvimApi.Window,
    width: Int
  ) -> Result<Void, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    let reqResult = self.sendRequest(method: "window_set_width", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetVar(
    window: NvimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Value, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Value in
      guard let result = Optional(value) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetPosition(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<[Int], NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NvimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_position", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetTabpage(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<NvimApi.Tabpage, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> NvimApi.Tabpage in
      guard let result = (NvimApi.Tabpage(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_get_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> NvimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowIsValid(
    window: NvimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Result<Bool, NvimApi.Error> {
    let params: [NvimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked, let error = self.blockedError() { return .failure(error) }

    let reqResult = self.sendRequest(method: "window_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }
}
