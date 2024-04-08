// Auto generated for nvim version 0.9.5.
// See bin/generate_api_methods.py

import Foundation
import MessagePack
import RxSwift

extension RxNeovimApi {

  public enum Error: Swift.Error {

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

extension RxNeovimApi {

  public func getAutocmds(
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func createAutocmd(
    event: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        event,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func delAutocmd(
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

  public func clearAutocmds(
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func createAugroup(
    name: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func delAugroupById(
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

  public func delAugroupByName(
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

  public func execAutocmds(
    event: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        event,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func bufLineCount(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func bufAttach(
    buffer: RxNeovimApi.Buffer,
    send_buffer: Bool,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .bool(send_buffer),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func bufDetach(
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

  public func bufGetLines(
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
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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

  public func bufSetLines(
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

  public func bufSetText(
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

  public func bufGetText(
    buffer: RxNeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(start_row)),
        .int(Int64(start_col)),
        .int(Int64(end_row)),
        .int(Int64(end_col)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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

  public func bufGetOffset(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(index)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func bufGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func bufGetChangedtick(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func bufGetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    errWhenBlocked: Bool = true
  ) -> Single<[Dictionary<String, RxNeovimApi.Value>]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(mode),
    ]

    let transform = { (_ value: Value) throws -> [Dictionary<String, RxNeovimApi.Value>] in
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        throw RxNeovimApi.Error.conversion(type: [Dictionary<String, RxNeovimApi.Value>].self)
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

  public func bufSetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    lhs: String,
    rhs: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(mode),
        .string(lhs),
        .string(rhs),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func bufDelKeymap(
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

  public func bufSetVar(
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

  public func bufDelVar(
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

  public func bufGetName(
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

  public func bufSetName(
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

  public func bufIsLoaded(
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

  public func bufDelete(
    buffer: RxNeovimApi.Buffer,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func bufIsValid(
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

  public func bufDelMark(
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

  public func bufSetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    line: Int,
    col: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
        .int(Int64(line)),
        .int(Int64(col)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func bufGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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

  public func bufCall(
    buffer: RxNeovimApi.Buffer,
    fun: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        fun,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func parseCmd(
    str: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(str),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func cmd(
    cmd: Dictionary<String, RxNeovimApi.Value>,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<String> {

    let params: [RxNeovimApi.Value] = [
        .map(cmd.mapToDict({ (Value.string($0), $1) })),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func createUserCommand(
    name: String,
    command: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        command,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func delUserCommand(
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

  public func bufCreateUserCommand(
    buffer: RxNeovimApi.Buffer,
    name: String,
    command: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
        command,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func bufDelUserCommand(
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

  public func getCommands(
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func bufGetCommands(
    buffer: RxNeovimApi.Buffer,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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
  public func exec(
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
  public func commandOutput(
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
  public func executeLua(
    code: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(code),
        args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func bufGetNumber(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func bufClearHighlight(
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
  public func bufSetVirtualText(
    buffer: RxNeovimApi.Buffer,
    src_id: Int,
    line: Int,
    chunks: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .int(Int64(line)),
        chunks,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func getHlById(
    hl_id: Int,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(hl_id)),
        .bool(rgb),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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
  public func getHlByName(
    name: String,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .bool(rgb),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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
  public func rInsert(
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
  public func rGetLine(
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
  public func rSetLine(
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
  public func rDelLine(
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
  public func rGetLineSlice(
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
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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
  public func rSetLineSlice(
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
  public func rSetVar(
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
      guard let result = (Optional(value)) else {
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
  public func rDelVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func wSetVar(
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
      guard let result = (Optional(value)) else {
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
  public func wDelVar(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func geSetVar(
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
      guard let result = (Optional(value)) else {
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
  public func geDelVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func etVar(
    name: String,
    value: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        value,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func elVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func getOptionInfo(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func createNamespace(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func getNamespaces(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func bufGetExtmarkById(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    id: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(ns_id)),
        .int(Int64(id)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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

  public func bufGetExtmarks(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    start: RxNeovimApi.Value,
    end: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(ns_id)),
        start,
        end,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func bufSetExtmark(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line: Int,
    col: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(ns_id)),
        .int(Int64(line)),
        .int(Int64(col)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func bufDelExtmark(
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

  public func bufAddHighlight(
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
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func bufClearNamespace(
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

  public func setDecorationProvider(
    ns_id: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(ns_id)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func getOptionValue(
    name: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func setOptionValue(
    name: String,
    value: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        value,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func getAllOptionsInfo(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func getOptionInfo2(
    name: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func setOption(
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

  public func getOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func bufGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func bufSetOption(
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

  public func winGetOption(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func winSetOption(
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

  public func tabpageListWins(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
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

  public func tabpageGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func tabpageSetVar(
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

  public func tabpageDelVar(
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

  public func tabpageGetWin(
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

  public func tabpageGetNumber(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func tabpageIsValid(
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

  public func uiAttach(
    width: Int,
    height: Int,
    options: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(width)),
        .int(Int64(height)),
        .map(options.mapToDict({ (Value.string($0), $1) })),
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
  public func tach(
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

  public func uiSetFocus(
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

  public func uiDetach(
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

  public func uiTryResize(
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

  public func uiSetOption(
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

  public func uiTryResizeGrid(
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

  public func uiPumSetHeight(
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

  public func uiPumSetBounds(
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

  public func getHlIdByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func getHl(
    ns_id: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(ns_id)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func setHl(
    ns_id: Int,
    name: String,
    val: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(ns_id)),
        .string(name),
        .map(val.mapToDict({ (Value.string($0), $1) })),
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

  public func setHlNs(
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

  public func setHlNsFast(
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

  public func feedkeys(
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

  public func input(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(keys),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func inputMouse(
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

  public func replaceTermcodes(
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

  public func execLua(
    code: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(code),
        args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func notify(
    msg: String,
    log_level: Int,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(msg),
        .int(Int64(log_level)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func strwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(text),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func listRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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

  public func getRuntimeFile(
    name: String,
    all: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .bool(all),
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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

  public func setCurrentDir(
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

  public func getCurrentLine(
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

  public func setCurrentLine(
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

  public func delCurrentLine(
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

  public func getVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func setVar(
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

  public func delVar(
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

  public func getVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func setVvar(
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

  public func echo(
    chunks: RxNeovimApi.Value,
    history: Bool,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        chunks,
        .bool(history),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func outWrite(
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

  public func errWrite(
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

  public func errWriteln(
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

  public func listBufs(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Buffer]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Buffer(v) })) else {
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

  public func getCurrentBuf(
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

  public func setCurrentBuf(
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

  public func listWins(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
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

  public func getCurrentWin(
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

  public func setCurrentWin(
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

  public func createBuf(
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

  public func openTerm(
    buffer: RxNeovimApi.Buffer,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func chanSend(
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

  public func listTabpages(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Tabpage]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Tabpage(v) })) else {
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

  public func getCurrentTabpage(
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

  public func setCurrentTabpage(
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

  public func paste(
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

  public func put(
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

  public func subscribe(
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

  public func unsubscribe(
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

  public func getColorByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func getColorMap(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func getContext(
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func loadContext(
    dict: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .map(dict.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func getMode(
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]
    return self
      .sendRequest(method: "nvim_get_mode", params: params)
      .map { value in
        guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
          throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
        }

        return result
      }
  }

  public func getKeymap(
    mode: String,
    errWhenBlocked: Bool = true
  ) -> Single<[Dictionary<String, RxNeovimApi.Value>]> {

    let params: [RxNeovimApi.Value] = [
        .string(mode),
    ]

    let transform = { (_ value: Value) throws -> [Dictionary<String, RxNeovimApi.Value>] in
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        throw RxNeovimApi.Error.conversion(type: [Dictionary<String, RxNeovimApi.Value>].self)
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

  public func setKeymap(
    mode: String,
    lhs: String,
    rhs: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .string(mode),
        .string(lhs),
        .string(rhs),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func delKeymap(
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

  public func getApiInfo(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func setClientInfo(
    name: String,
    version: Dictionary<String, RxNeovimApi.Value>,
    type: String,
    methods: Dictionary<String, RxNeovimApi.Value>,
    attributes: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .map(version.mapToDict({ (Value.string($0), $1) })),
        .string(type),
        .map(methods.mapToDict({ (Value.string($0), $1) })),
        .map(attributes.mapToDict({ (Value.string($0), $1) })),
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

  public func getChanInfo(
    chan: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(chan)),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func listChans(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func callAtomic(
    calls: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        calls,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func listUis(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func getProcChildren(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(pid)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func getProc(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(pid)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func selectPopupmenuItem(
    item: Int,
    insert: Bool,
    finish: Bool,
    opts: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(item)),
        .bool(insert),
        .bool(finish),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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

  public func delMark(
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

  public func getMark(
    name: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func evalStatusline(
    str: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(str),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func exec2(
    src: String,
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(src),
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func command(
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

  public func eval(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(expr),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func callFunction(
    fn: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(fn),
        args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func callDictFunction(
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
      guard let result = (Optional(value)) else {
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

  public func parseExpression(
    expr: String,
    flags: String,
    highlight: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(expr),
        .string(flags),
        .bool(highlight),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func openWin(
    buffer: RxNeovimApi.Buffer,
    enter: Bool,
    config: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .bool(enter),
        .map(config.mapToDict({ (Value.string($0), $1) })),
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

  public func winSetConfig(
    window: RxNeovimApi.Window,
    config: Dictionary<String, RxNeovimApi.Value>,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        .map(config.mapToDict({ (Value.string($0), $1) })),
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

  public func winGetConfig(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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

  public func winGetBuf(
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

  public func winSetBuf(
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

  public func winGetCursor(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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

  public func winSetCursor(
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

  public func winGetHeight(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func winSetHeight(
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

  public func winGetWidth(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func winSetWidth(
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

  public func winGetVar(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func winSetVar(
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

  public func winDelVar(
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

  public func winGetPosition(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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

  public func winGetTabpage(
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

  public func winGetNumber(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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

  public func winIsValid(
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

  public func winHide(
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

  public func winClose(
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

  public func winCall(
    window: RxNeovimApi.Window,
    fun: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        fun,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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

  public func winSetHlNs(
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

  @available(*, deprecated, message: "This method has been deprecated.")
  public func rLineCount(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func rGetLines(
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
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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
  public func rSetLines(
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
  public func rGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func rGetName(
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
  public func rSetName(
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
  public func rIsValid(
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
  public func rGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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
  public func ommandOutput(
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
  public func rGetNumber(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func rClearHighlight(
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
  public func rAddHighlight(
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
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func etOption(
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
  public func etOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func rGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func rSetOption(
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
  public func wGetOption(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func wSetOption(
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
  public func geGetWindows(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
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
  public func geGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func geGetWindow(
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
  public func geIsValid(
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
  public func tach(
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
  public func yResize(
    width: Int,
    height: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(width)),
        .int(Int64(height)),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func eedkeys(
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
  public func nput(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(keys),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func eplaceTermcodes(
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
  public func trwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(text),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func istRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
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
  public func hangeDirectory(
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
  public func etCurrentLine(
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
  public func etCurrentLine(
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
  public func elCurrentLine(
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
  public func etVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func etVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func utWrite(
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
  public func rrWrite(
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
  public func eportError(
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
  public func etBuffers(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Buffer]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Buffer(v) })) else {
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
  public func etCurrentBuffer(
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
  public func etCurrentBuffer(
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
  public func etWindows(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
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
  public func etCurrentWindow(
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
  public func etCurrentWindow(
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
  public func etTabpages(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Tabpage]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Tabpage(v) })) else {
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
  public func etCurrentTabpage(
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
  public func etCurrentTabpage(
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
  public func ubscribe(
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
  public func nsubscribe(
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
  public func ameToColor(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func etColorMap(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> in
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
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
  public func etApiInfo(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func ommand(
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
  public func val(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(expr),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func allFunction(
    fn: String,
    args: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(fn),
        args,
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func wGetBuffer(
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
  public func wGetCursor(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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
  public func wSetCursor(
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
  public func wGetHeight(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func wSetHeight(
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
  public func wGetWidth(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> Int in
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
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
  public func wSetWidth(
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
  public func wGetVar(
    window: RxNeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = (Optional(value)) else {
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
  public func wGetPosition(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    let transform = { (_ value: Value) throws -> [Int] in
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
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
  public func wGetTabpage(
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
  public func wIsValid(
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

extension RxNeovimApi.Buffer {

  public init?(_ value: RxNeovimApi.Value) {
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

extension RxNeovimApi.Window {

  public init?(_ value: RxNeovimApi.Value) {
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

extension RxNeovimApi.Tabpage {

  public init?(_ value: RxNeovimApi.Value) {
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

fileprivate func msgPackDictToSwift(_ dict: Dictionary<RxNeovimApi.Value, RxNeovimApi.Value>?) -> Dictionary<String, RxNeovimApi.Value>? {
  return dict?.compactMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

fileprivate func msgPackArrayDictToSwift(_ array: [RxNeovimApi.Value]?) -> [Dictionary<String, RxNeovimApi.Value>]? {
  return array?
    .compactMap { v in v.dictionaryValue }
    .compactMap { d in msgPackDictToSwift(d) }
}

extension Dictionary {

  fileprivate func mapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)) rethrows -> Dictionary<K, V> {
    let array = try self.map(transform)
    return tuplesToDict(array)
  }

  fileprivate func compactMapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)?) rethrows -> Dictionary<K, V> {
    let array = try self.compactMap(transform)
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
