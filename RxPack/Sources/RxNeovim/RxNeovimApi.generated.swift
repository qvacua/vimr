// Auto generated for nvim version 0.10.4.
// See bin/generate_api_methods.py

import Foundation
import MessagePack
import RxSwift

public extension RxNeovimApi {
  enum Error: Swift.Error {
    public static let exceptionRawValue = UInt64(0)
    public static let validationRawValue = UInt64(1)

    case exception(message: String)
    case validation(message: String)
    case blocked
    case conversion(type: Any.Type)
    case unknown

    init(_ value: RxNeovimApi.Value?) {
      let array = value?.arrayValue
      guard array?.count == 2 else {
        self = .unknown
        return
      }

      guard let rawValue = array?[0].uint64Value, let message = array?[1].stringValue else {
        self = .unknown
        return
      }

      switch rawValue {
      case Error.exceptionRawValue: self = .exception(message: message)
      case Error.validationRawValue: self = .validation(message: message)
      default: self = .unknown
      }
    }
  }
}

public extension RxNeovimApi {
  func nvimGetAutocmds(
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_autocmds", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_autocmds", params: params)
      .map(transform)
  }

  func nvimCreateAutocmd(
    event: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      event,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_create_autocmd", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_create_autocmd", params: params)
      .map(transform)
  }

  func nvimDelAutocmd(
    id: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(id)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_autocmd", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_autocmd", params: params)
      .asCompletable()
  }

  func nvimClearAutocmds(
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_clear_autocmds", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_clear_autocmds", params: params)
      .asCompletable()
  }

  func nvimCreateAugroup(
    name: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_create_augroup", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_create_augroup", params: params)
      .map(transform)
  }

  func nvimDelAugroupById(
    id: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(id)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_augroup_by_id", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_augroup_by_id", params: params)
      .asCompletable()
  }

  func nvimDelAugroupByName(
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_augroup_by_name", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_augroup_by_name", params: params)
      .asCompletable()
  }

  func nvimExecAutocmds(
    event: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      event,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_exec_autocmds", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_exec_autocmds", params: params)
      .asCompletable()
  }

  func nvimBufLineCount(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_line_count", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_line_count", params: params)
      .map(transform)
  }

  func nvimBufAttach(
    buffer: RxNeovimApi.Buffer,
    send_buffer: Bool,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .bool(send_buffer),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_attach", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_attach", params: params)
      .map(transform)
  }

  func nvimBufDetach(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_detach", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_detach", params: params)
      .map(transform)
  }

  func nvimBufGetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_lines", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_lines", params: params)
      .map(transform)
  }

  func nvimBufSetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_lines", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_set_lines", params: params)
      .asCompletable()
  }

  func nvimBufSetText(
    buffer: RxNeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_text", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_set_text", params: params)
      .asCompletable()
  }

  func nvimBufGetText(
    buffer: RxNeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_text", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_text", params: params)
      .map(transform)
  }

  func nvimBufGetOffset(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_offset", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_offset", params: params)
      .map(transform)
  }

  func nvimBufGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_var", params: params)
      .map(transform)
  }

  func nvimBufGetChangedtick(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_changedtick", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_changedtick", params: params)
      .map(transform)
  }

  func nvimBufGetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    errWhenBlocked: Bool = true
  ) -> Single<[[String: RxNeovimApi.Value]]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
    ]

    let transform = { (_ value: Value) throws -> [[String: RxNeovimApi.Value]] in
      guard let result = msgPackArrayDictToSwift(value.arrayValue) else {
        throw RxNeovimApi.Error.conversion(type: [[String: RxNeovimApi.Value]].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_keymap", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_keymap", params: params)
      .map(transform)
  }

  func nvimBufSetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_keymap", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_set_keymap", params: params)
      .asCompletable()
  }

  func nvimBufDelKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    lhs: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_del_keymap", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_del_keymap", params: params)
      .asCompletable()
  }

  func nvimBufSetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_set_var", params: params)
      .asCompletable()
  }

  func nvimBufDelVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_del_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_del_var", params: params)
      .asCompletable()
  }

  func nvimBufGetName(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_name", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_name", params: params)
      .map(transform)
  }

  func nvimBufSetName(
    buffer: RxNeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_name", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_set_name", params: params)
      .asCompletable()
  }

  func nvimBufIsLoaded(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_is_loaded", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_is_loaded", params: params)
      .map(transform)
  }

  func nvimBufDelete(
    buffer: RxNeovimApi.Buffer,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_delete", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_delete", params: params)
      .asCompletable()
  }

  func nvimBufIsValid(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_is_valid", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_is_valid", params: params)
      .map(transform)
  }

  func nvimBufDelMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_del_mark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_del_mark", params: params)
      .map(transform)
  }

  func nvimBufSetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    line: Int,
    col: Int,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      .int(Int64(line)),
      .int(Int64(col)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_mark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_set_mark", params: params)
      .map(transform)
  }

  func nvimBufGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_mark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_mark", params: params)
      .map(transform)
  }

  func nvimBufCall(
    buffer: RxNeovimApi.Buffer,
    fun: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      fun,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_call", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_call", params: params)
      .map(transform)
  }

  func nvimParseCmd(
    str: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(str),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_parse_cmd", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_parse_cmd", params: params)
      .map(transform)
  }

  func nvimCmd(
    cmd: [String: RxNeovimApi.Value],
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .map(cmd.mapToDict { (Value.string($0), $1) }),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_cmd", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_cmd", params: params)
      .map(transform)
  }

  func nvimCreateUserCommand(
    name: String,
    command: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      command,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_create_user_command", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_create_user_command", params: params)
      .asCompletable()
  }

  func nvimDelUserCommand(
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_user_command", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_user_command", params: params)
      .asCompletable()
  }

  func nvimBufCreateUserCommand(
    buffer: RxNeovimApi.Buffer,
    name: String,
    command: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      command,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_create_user_command", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_create_user_command", params: params)
      .asCompletable()
  }

  func nvimBufDelUserCommand(
    buffer: RxNeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_del_user_command", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_del_user_command", params: params)
      .asCompletable()
  }

  func nvimGetCommands(
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_commands", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_commands", params: params)
      .map(transform)
  }

  func nvimBufGetCommands(
    buffer: RxNeovimApi.Buffer,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_commands", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_commands", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimExec(
    src: String,
    output: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .string(src),
      .bool(output),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_exec", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_exec", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimCommandOutput(
    command: String,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .string(command),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_command_output", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_command_output", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimExecuteLua(
    code: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(code),
      args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_execute_lua", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_execute_lua", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufGetNumber(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_number", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_number", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufClearHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_clear_highlight", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_clear_highlight", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufSetVirtualText(
    buffer: RxNeovimApi.Buffer,
    src_id: Int,
    line: Int,
    chunks: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(src_id)),
      .int(Int64(line)),
      chunks,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_virtual_text", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_set_virtual_text", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetHlById(
    hl_id: Int,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(hl_id)),
      .bool(rgb),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_hl_by_id", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_hl_by_id", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetHlByName(
    name: String,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .bool(rgb),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_hl_by_name", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_hl_by_name", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferInsert(
    buffer: RxNeovimApi.Buffer,
    lnum: Int,
    lines: [String],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(lnum)),
      .array(lines.map { .string($0) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_insert", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_insert", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLine(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_line", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_line", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLine(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    line: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
      .string(line),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_set_line", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_set_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferDelLine(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_del_line", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_del_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLineSlice(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_line_slice", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_line_slice", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLineSlice(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_set_line_slice", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_set_line_slice", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_set_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferDelVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_del_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetVar(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_set_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowDelVar(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_del_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageSetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    value: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "tabpage_set_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "tabpage_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageDelVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "tabpage_del_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "tabpage_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetVar(
    name: String,
    value: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_set_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimDelVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_del_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetOptionInfo(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_option_info", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_option_info", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimSetOption(
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimGetOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_option", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_option", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufSetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimWinGetOption(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_option", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimWinSetOption(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimCallAtomic(
    calls: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      calls,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_call_atomic", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_call_atomic", params: params)
      .map(transform)
  }

  func nvimCreateNamespace(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_create_namespace", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_create_namespace", params: params)
      .map(transform)
  }

  func nvimGetNamespaces(
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_namespaces", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_namespaces", params: params)
      .map(transform)
  }

  func nvimBufGetExtmarkById(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    id: Int,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_extmark_by_id", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_extmark_by_id", params: params)
      .map(transform)
  }

  func nvimBufGetExtmarks(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    start: RxNeovimApi.Value,
    end: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      start,
      end,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_get_extmarks", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_get_extmarks", params: params)
      .map(transform)
  }

  func nvimBufSetExtmark(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line: Int,
    col: Int,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line)),
      .int(Int64(col)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_set_extmark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_set_extmark", params: params)
      .map(transform)
  }

  func nvimBufDelExtmark(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    id: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(id)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_del_extmark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_del_extmark", params: params)
      .map(transform)
  }

  func nvimBufAddHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .string(hl_group),
      .int(Int64(line)),
      .int(Int64(col_start)),
      .int(Int64(col_end)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_add_highlight", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_buf_add_highlight", params: params)
      .map(transform)
  }

  func nvimBufClearNamespace(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_buf_clear_namespace", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_buf_clear_namespace", params: params)
      .asCompletable()
  }

  func nvimSetDecorationProvider(
    ns_id: Int,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_decoration_provider", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_decoration_provider", params: params)
      .asCompletable()
  }

  func nvimGetOptionValue(
    name: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_option_value", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_option_value", params: params)
      .map(transform)
  }

  func nvimSetOptionValue(
    name: String,
    value: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_option_value", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_option_value", params: params)
      .asCompletable()
  }

  func nvimGetAllOptionsInfo(
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_all_options_info", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_all_options_info", params: params)
      .map(transform)
  }

  func nvimGetOptionInfo2(
    name: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_option_info2", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_option_info2", params: params)
      .map(transform)
  }

  func nvimTabpageListWins(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Window(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_list_wins", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_tabpage_list_wins", params: params)
      .map(transform)
  }

  func nvimTabpageGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_tabpage_get_var", params: params)
      .map(transform)
  }

  func nvimTabpageSetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_set_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_tabpage_set_var", params: params)
      .asCompletable()
  }

  func nvimTabpageDelVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_del_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_tabpage_del_var", params: params)
      .asCompletable()
  }

  func nvimTabpageGetWin(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_get_win", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_tabpage_get_win", params: params)
      .map(transform)
  }

  func nvimTabpageSetWin(
    tabpage: RxNeovimApi.Tabpage,
    win: RxNeovimApi.Window,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .int(Int64(win.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_set_win", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_tabpage_set_win", params: params)
      .asCompletable()
  }

  func nvimTabpageGetNumber(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_get_number", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_tabpage_get_number", params: params)
      .map(transform)
  }

  func nvimTabpageIsValid(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_tabpage_is_valid", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_tabpage_is_valid", params: params)
      .map(transform)
  }

  func nvimUiAttach(
    width: Int,
    height: Int,
    options: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .map(options.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_attach", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_attach", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiAttach(
    width: Int,
    height: Int,
    enable_rgb: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .bool(enable_rgb),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "ui_attach", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "ui_attach", params: params)
      .asCompletable()
  }

  func nvimUiSetFocus(
    gained: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .bool(gained),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_set_focus", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_set_focus", params: params)
      .asCompletable()
  }

  func nvimUiDetach(
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_detach", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_detach", params: params)
      .asCompletable()
  }

  func nvimUiTryResize(
    width: Int,
    height: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_try_resize", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_try_resize", params: params)
      .asCompletable()
  }

  func nvimUiSetOption(
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_set_option", params: params)
      .asCompletable()
  }

  func nvimUiTryResizeGrid(
    grid: Int,
    width: Int,
    height: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(grid)),
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_try_resize_grid", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_try_resize_grid", params: params)
      .asCompletable()
  }

  func nvimUiPumSetHeight(
    height: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_pum_set_height", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_pum_set_height", params: params)
      .asCompletable()
  }

  func nvimUiPumSetBounds(
    width: Float,
    height: Float,
    row: Float,
    col: Float,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .float(width),
      .float(height),
      .float(row),
      .float(col),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_pum_set_bounds", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_pum_set_bounds", params: params)
      .asCompletable()
  }

  func nvimUiTermEvent(
    event: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_ui_term_event", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_ui_term_event", params: params)
      .asCompletable()
  }

  func nvimGetHlIdByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_hl_id_by_name", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_hl_id_by_name", params: params)
      .map(transform)
  }

  func nvimGetHl(
    ns_id: Int,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_hl", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_hl", params: params)
      .map(transform)
  }

  func nvimSetHl(
    ns_id: Int,
    name: String,
    val: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
      .string(name),
      .map(val.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_hl", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_hl", params: params)
      .asCompletable()
  }

  func nvimGetHlNs(
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_hl_ns", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_hl_ns", params: params)
      .map(transform)
  }

  func nvimSetHlNs(
    ns_id: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_hl_ns", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_hl_ns", params: params)
      .asCompletable()
  }

  func nvimSetHlNsFast(
    ns_id: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_hl_ns_fast", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_hl_ns_fast", params: params)
      .asCompletable()
  }

  func nvimFeedkeys(
    keys: String,
    mode: String,
    escape_ks: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_feedkeys", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_feedkeys", params: params)
      .asCompletable()
  }

  func nvimInput(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(keys),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_input", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_input", params: params)
      .map(transform)
  }

  func nvimInputMouse(
    button: String,
    action: String,
    modifier: String,
    grid: Int,
    row: Int,
    col: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(button),
      .string(action),
      .string(modifier),
      .int(Int64(grid)),
      .int(Int64(row)),
      .int(Int64(col)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_input_mouse", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_input_mouse", params: params)
      .asCompletable()
  }

  func nvimReplaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .string(str),
      .bool(from_part),
      .bool(do_lt),
      .bool(special),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_replace_termcodes", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_replace_termcodes", params: params)
      .map(transform)
  }

  func nvimExecLua(
    code: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(code),
      args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_exec_lua", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_exec_lua", params: params)
      .map(transform)
  }

  func nvimNotify(
    msg: String,
    log_level: Int,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(msg),
      .int(Int64(log_level)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_notify", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_notify", params: params)
      .map(transform)
  }

  func nvimStrwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(text),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_strwidth", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_strwidth", params: params)
      .map(transform)
  }

  func nvimListRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_list_runtime_paths", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_list_runtime_paths", params: params)
      .map(transform)
  }

  func nvimGetRuntimeFile(
    name: String,
    all: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .bool(all),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_runtime_file", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_runtime_file", params: params)
      .map(transform)
  }

  func nvimSetCurrentDir(
    dir: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(dir),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_current_dir", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_current_dir", params: params)
      .asCompletable()
  }

  func nvimGetCurrentLine(
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_current_line", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_current_line", params: params)
      .map(transform)
  }

  func nvimSetCurrentLine(
    line: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(line),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_current_line", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_current_line", params: params)
      .asCompletable()
  }

  func nvimDelCurrentLine(
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_current_line", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_current_line", params: params)
      .asCompletable()
  }

  func nvimGetVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_var", params: params)
      .map(transform)
  }

  func nvimSetVar(
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_var", params: params)
      .asCompletable()
  }

  func nvimDelVar(
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_var", params: params)
      .asCompletable()
  }

  func nvimGetVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_vvar", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_vvar", params: params)
      .map(transform)
  }

  func nvimSetVvar(
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_vvar", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_vvar", params: params)
      .asCompletable()
  }

  func nvimEcho(
    chunks: RxNeovimApi.Value,
    history: Bool,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      chunks,
      .bool(history),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_echo", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_echo", params: params)
      .asCompletable()
  }

  func nvimOutWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_out_write", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_out_write", params: params)
      .asCompletable()
  }

  func nvimErrWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_err_write", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_err_write", params: params)
      .asCompletable()
  }

  func nvimErrWriteln(
    str: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_err_writeln", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_err_writeln", params: params)
      .asCompletable()
  }

  func nvimListBufs(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Buffer]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Buffer(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_list_bufs", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_list_bufs", params: params)
      .map(transform)
  }

  func nvimGetCurrentBuf(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_current_buf", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_current_buf", params: params)
      .map(transform)
  }

  func nvimSetCurrentBuf(
    buffer: RxNeovimApi.Buffer,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_current_buf", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_current_buf", params: params)
      .asCompletable()
  }

  func nvimListWins(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Window(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_list_wins", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_list_wins", params: params)
      .map(transform)
  }

  func nvimGetCurrentWin(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_current_win", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_current_win", params: params)
      .map(transform)
  }

  func nvimSetCurrentWin(
    window: RxNeovimApi.Window,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_current_win", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_current_win", params: params)
      .asCompletable()
  }

  func nvimCreateBuf(
    listed: Bool,
    scratch: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
      .bool(listed),
      .bool(scratch),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_create_buf", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_create_buf", params: params)
      .map(transform)
  }

  func nvimOpenTerm(
    buffer: RxNeovimApi.Buffer,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_open_term", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_open_term", params: params)
      .map(transform)
  }

  func nvimChanSend(
    chan: Int,
    data: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(chan)),
      .string(data),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_chan_send", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_chan_send", params: params)
      .asCompletable()
  }

  func nvimListTabpages(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Tabpage]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Tabpage(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_list_tabpages", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_list_tabpages", params: params)
      .map(transform)
  }

  func nvimGetCurrentTabpage(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Tabpage in
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_current_tabpage", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_current_tabpage", params: params)
      .map(transform)
  }

  func nvimSetCurrentTabpage(
    tabpage: RxNeovimApi.Tabpage,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_current_tabpage", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_current_tabpage", params: params)
      .asCompletable()
  }

  func nvimPaste(
    data: String,
    crlf: Bool,
    phase: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .string(data),
      .bool(crlf),
      .int(Int64(phase)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_paste", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_paste", params: params)
      .map(transform)
  }

  func nvimPut(
    lines: [String],
    type: String,
    after: Bool,
    follow: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .array(lines.map { .string($0) }),
      .string(type),
      .bool(after),
      .bool(follow),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_put", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_put", params: params)
      .asCompletable()
  }

  func nvimSubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_subscribe", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_subscribe", params: params)
      .asCompletable()
  }

  func nvimUnsubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_unsubscribe", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_unsubscribe", params: params)
      .asCompletable()
  }

  func nvimGetColorByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_color_by_name", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_color_by_name", params: params)
      .map(transform)
  }

  func nvimGetColorMap(
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_color_map", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_color_map", params: params)
      .map(transform)
  }

  func nvimGetContext(
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_context", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_context", params: params)
      .map(transform)
  }

  func nvimLoadContext(
    dict: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .map(dict.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_load_context", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_load_context", params: params)
      .map(transform)
  }

  func nvimGetMode(
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]
    return self
      .sendRequest(method: "nvim_get_mode", params: params)
      .map { value in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
        }

        return result
      }
  }

  func nvimGetKeymap(
    mode: String,
    errWhenBlocked: Bool = true
  ) -> Single<[[String: RxNeovimApi.Value]]> {
    let params: [RxNeovimApi.Value] = [
      .string(mode),
    ]

    let transform = { (_ value: Value) throws -> [[String: RxNeovimApi.Value]] in
      guard let result = msgPackArrayDictToSwift(value.arrayValue) else {
        throw RxNeovimApi.Error.conversion(type: [[String: RxNeovimApi.Value]].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_keymap", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_keymap", params: params)
      .map(transform)
  }

  func nvimSetKeymap(
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_keymap", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_keymap", params: params)
      .asCompletable()
  }

  func nvimDelKeymap(
    mode: String,
    lhs: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(mode),
      .string(lhs),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_keymap", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_del_keymap", params: params)
      .asCompletable()
  }

  func nvimGetApiInfo(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_api_info", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_api_info", params: params)
      .map(transform)
  }

  func nvimSetClientInfo(
    name: String,
    version: [String: RxNeovimApi.Value],
    type: String,
    methods: [String: RxNeovimApi.Value],
    attributes: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .map(version.mapToDict { (Value.string($0), $1) }),
      .string(type),
      .map(methods.mapToDict { (Value.string($0), $1) }),
      .map(attributes.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_set_client_info", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_set_client_info", params: params)
      .asCompletable()
  }

  func nvimGetChanInfo(
    chan: Int,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(chan)),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_chan_info", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_chan_info", params: params)
      .map(transform)
  }

  func nvimListChans(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_list_chans", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_list_chans", params: params)
      .map(transform)
  }

  func nvimListUis(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_list_uis", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_list_uis", params: params)
      .map(transform)
  }

  func nvimGetProcChildren(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(pid)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_proc_children", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_proc_children", params: params)
      .map(transform)
  }

  func nvimGetProc(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(pid)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_proc", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_proc", params: params)
      .map(transform)
  }

  func nvimSelectPopupmenuItem(
    item: Int,
    insert: Bool,
    finish: Bool,
    opts: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(item)),
      .bool(insert),
      .bool(finish),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_select_popupmenu_item", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_select_popupmenu_item", params: params)
      .asCompletable()
  }

  func nvimDelMark(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_del_mark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_del_mark", params: params)
      .map(transform)
  }

  func nvimGetMark(
    name: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_get_mark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_get_mark", params: params)
      .map(transform)
  }

  func nvimEvalStatusline(
    str: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(str),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_eval_statusline", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_eval_statusline", params: params)
      .map(transform)
  }

  func nvimExec2(
    src: String,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(src),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_exec2", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_exec2", params: params)
      .map(transform)
  }

  func nvimCommand(
    command: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(command),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_command", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_command", params: params)
      .asCompletable()
  }

  func nvimEval(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(expr),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_eval", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_eval", params: params)
      .map(transform)
  }

  func nvimCallFunction(
    fn: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(fn),
      args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_call_function", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_call_function", params: params)
      .map(transform)
  }

  func nvimCallDictFunction(
    dict: RxNeovimApi.Value,
    fn: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      dict,
      .string(fn),
      args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_call_dict_function", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_call_dict_function", params: params)
      .map(transform)
  }

  func nvimParseExpression(
    expr: String,
    flags: String,
    highlight: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .string(expr),
      .string(flags),
      .bool(highlight),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_parse_expression", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_parse_expression", params: params)
      .map(transform)
  }

  func nvimOpenWin(
    buffer: RxNeovimApi.Buffer,
    enter: Bool,
    config: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .bool(enter),
      .map(config.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_open_win", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_open_win", params: params)
      .map(transform)
  }

  func nvimWinSetConfig(
    window: RxNeovimApi.Window,
    config: [String: RxNeovimApi.Value],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .map(config.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_config", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_config", params: params)
      .asCompletable()
  }

  func nvimWinGetConfig(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_config", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_config", params: params)
      .map(transform)
  }

  func nvimWinGetBuf(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_buf", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_buf", params: params)
      .map(transform)
  }

  func nvimWinSetBuf(
    window: RxNeovimApi.Window,
    buffer: RxNeovimApi.Buffer,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(buffer.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_buf", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_buf", params: params)
      .asCompletable()
  }

  func nvimWinGetCursor(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_cursor", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_cursor", params: params)
      .map(transform)
  }

  func nvimWinSetCursor(
    window: RxNeovimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_cursor", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_cursor", params: params)
      .asCompletable()
  }

  func nvimWinGetHeight(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_height", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_height", params: params)
      .map(transform)
  }

  func nvimWinSetHeight(
    window: RxNeovimApi.Window,
    height: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_height", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_height", params: params)
      .asCompletable()
  }

  func nvimWinGetWidth(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_width", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_width", params: params)
      .map(transform)
  }

  func nvimWinSetWidth(
    window: RxNeovimApi.Window,
    width: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_width", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_width", params: params)
      .asCompletable()
  }

  func nvimWinGetVar(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_var", params: params)
      .map(transform)
  }

  func nvimWinSetVar(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_var", params: params)
      .asCompletable()
  }

  func nvimWinDelVar(
    window: RxNeovimApi.Window,
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_del_var", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_del_var", params: params)
      .asCompletable()
  }

  func nvimWinGetPosition(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_position", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_position", params: params)
      .map(transform)
  }

  func nvimWinGetTabpage(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Tabpage in
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_tabpage", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_tabpage", params: params)
      .map(transform)
  }

  func nvimWinGetNumber(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_get_number", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_get_number", params: params)
      .map(transform)
  }

  func nvimWinIsValid(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_is_valid", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_is_valid", params: params)
      .map(transform)
  }

  func nvimWinHide(
    window: RxNeovimApi.Window,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_hide", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_hide", params: params)
      .asCompletable()
  }

  func nvimWinClose(
    window: RxNeovimApi.Window,
    force: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .bool(force),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_close", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_close", params: params)
      .asCompletable()
  }

  func nvimWinCall(
    window: RxNeovimApi.Window,
    fun: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      fun,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_call", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_call", params: params)
      .map(transform)
  }

  func nvimWinSetHlNs(
    window: RxNeovimApi.Window,
    ns_id: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(ns_id)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_set_hl_ns", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "nvim_win_set_hl_ns", params: params)
      .asCompletable()
  }

  func nvimWinTextHeight(
    window: RxNeovimApi.Window,
    opts: [String: RxNeovimApi.Value],
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "nvim_win_text_height", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "nvim_win_text_height", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferLineCount(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_line_count", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_line_count", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_lines", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_lines", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_set_lines", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_set_lines", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetName(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_name", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_name", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetName(
    buffer: RxNeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_set_name", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_set_name", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferIsValid(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_is_valid", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_is_valid", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_mark", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_mark", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCommandOutput(
    command: String,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .string(command),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_command_output", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_command_output", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetNumber(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_number", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_number", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferClearHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_clear_highlight", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_clear_highlight", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetOption(
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_option", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_get_option", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "buffer_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetOption(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_option", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetOption(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_set_option", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "window_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferAddHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .string(hl_group),
      .int(Int64(line)),
      .int(Int64(col_start)),
      .int(Int64(col_end)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "buffer_add_highlight", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "buffer_add_highlight", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetWindows(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Window(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "tabpage_get_windows", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "tabpage_get_windows", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "tabpage_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "tabpage_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetWindow(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "tabpage_get_window", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "tabpage_get_window", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageIsValid(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "tabpage_is_valid", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "tabpage_is_valid", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiDetach(
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "ui_detach", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "ui_detach", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiTryResize(
    width: Int,
    height: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "ui_try_resize", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "ui_try_resize", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimFeedkeys(
    keys: String,
    mode: String,
    escape_ks: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_feedkeys", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_feedkeys", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimInput(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(keys),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_input", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_input", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimReplaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
      .string(str),
      .bool(from_part),
      .bool(do_lt),
      .bool(special),
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_replace_termcodes", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_replace_termcodes", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimStrwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(text),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_strwidth", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_strwidth", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimListRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_list_runtime_paths", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_list_runtime_paths", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimChangeDirectory(
    dir: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(dir),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_change_directory", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_change_directory", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentLine(
    errWhenBlocked: Bool = true
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_current_line", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_current_line", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentLine(
    line: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(line),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_set_current_line", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_set_current_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimDelCurrentLine(
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_del_current_line", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_del_current_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_vvar", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_vvar", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimOutWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_out_write", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_out_write", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimErrWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_err_write", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_err_write", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimReportError(
    str: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_report_error", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_report_error", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetBuffers(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Buffer]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Buffer(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_buffers", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_buffers", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentBuffer(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_current_buffer", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_current_buffer", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentBuffer(
    buffer: RxNeovimApi.Buffer,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_set_current_buffer", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_set_current_buffer", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetWindows(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Window(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_windows", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_windows", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentWindow(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_current_window", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_current_window", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentWindow(
    window: RxNeovimApi.Window,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_set_current_window", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_set_current_window", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetTabpages(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Tabpage]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Tabpage(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_tabpages", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_tabpages", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentTabpage(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Tabpage in
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_current_tabpage", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_current_tabpage", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentTabpage(
    tabpage: RxNeovimApi.Tabpage,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_set_current_tabpage", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_set_current_tabpage", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_subscribe", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_subscribe", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimUnsubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_unsubscribe", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_unsubscribe", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimNameToColor(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_name_to_color", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_name_to_color", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetColorMap(
    errWhenBlocked: Bool = true
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_color_map", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_color_map", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetApiInfo(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_get_api_info", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_get_api_info", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCommand(
    command: String,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(command),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_command", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "vim_command", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimEval(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(expr),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_eval", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_eval", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCallFunction(
    fn: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .string(fn),
      args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "vim_call_function", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "vim_call_function", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetBuffer(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_buffer", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_buffer", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetCursor(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_cursor", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_cursor", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetCursor(
    window: RxNeovimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_set_cursor", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "window_set_cursor", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetHeight(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_height", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_height", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetHeight(
    window: RxNeovimApi.Window,
    height: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_set_height", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "window_set_height", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetWidth(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_width", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_width", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetWidth(
    window: RxNeovimApi.Window,
    width: Int,
    expectsReturnValue: Bool = false
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_set_width", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "window_set_width", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetVar(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_var", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetPosition(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_position", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_position", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetTabpage(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Tabpage in
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_get_tabpage", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_get_tabpage", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowIsValid(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Bool in
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "window_is_valid", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "window_is_valid", params: params)
      .map(transform)
  }
}

public extension RxNeovimApi.Buffer {
  init?(_ value: RxNeovimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == 0 else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.int64Value else {
      return nil
    }

    self.handle = Int(handle)
  }
}

public extension RxNeovimApi.Window {
  init?(_ value: RxNeovimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == 1 else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.int64Value else {
      return nil
    }

    self.handle = Int(handle)
  }
}

public extension RxNeovimApi.Tabpage {
  init?(_ value: RxNeovimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == 2 else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.int64Value else {
      return nil
    }

    self.handle = Int(handle)
  }
}

private func msgPackDictToSwift(_ dict: [RxNeovimApi.Value: RxNeovimApi.Value]?)
  -> [String: RxNeovimApi.Value]?
{
  dict?.compactMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

private func msgPackArrayDictToSwift(_ array: [RxNeovimApi.Value]?)
  -> [[String: RxNeovimApi.Value]]?
{
  array?
    .compactMap { v in v.dictionaryValue }
    .compactMap { d in msgPackDictToSwift(d) }
}

private extension Dictionary {
  func mapToDict<
    K,
    V
  >(_ transform: ((key: Key, value: Value)) throws -> (K, V)) rethrows -> [K: V] {
    let array = try self.map(transform)
    return self.tuplesToDict(array)
  }

  func compactMapToDict<
    K,
    V
  >(_ transform: ((key: Key, value: Value)) throws -> (K, V)?) rethrows -> [K: V] {
    let array = try self.compactMap(transform)
    return self.tuplesToDict(array)
  }

  func tuplesToDict<K: Hashable, V, S: Sequence>(_ sequence: S)
    -> [K: V] where S.Iterator.Element == (K, V)
  {
    var result = [K: V](minimumCapacity: sequence.underestimatedCount)

    for (key, value) in sequence {
      result[key] = value
    }

    return result
  }
}
