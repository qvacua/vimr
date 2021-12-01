// Auto generated for nvim version 0.6.0.
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

  public func bufLineCount(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_line_count", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_line_count", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_attach", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_attach", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func bufDetach(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
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
          self.rpc(method: "nvim_buf_detach", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_detach", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> [String] {
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_lines", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_lines", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_buf_set_lines", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_set_lines", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_buf_set_text", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_set_text", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
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

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_offset", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_offset", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_var", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_var", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func bufGetChangedtick(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_changedtick", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_changedtick", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> [Dictionary<String, RxNeovimApi.Value>] {
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        throw RxNeovimApi.Error.conversion(type: [Dictionary<String, RxNeovimApi.Value>].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_keymap", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_keymap", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_buf_set_keymap", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_set_keymap", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_buf_del_keymap", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_del_keymap", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
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

    func transform(_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_commands", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_commands", params: params, expectsReturnValue: true)
      .map(transform)
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
          self.rpc(method: "nvim_buf_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_set_var", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_buf_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_option", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_option", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_buf_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_set_option", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func bufGetName(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<String> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_name", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_name", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_buf_set_name", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_set_name", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func bufIsLoaded(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
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
          self.rpc(method: "nvim_buf_is_loaded", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_is_loaded", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_buf_delete", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_delete", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func bufIsValid(
    buffer: RxNeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
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
          self.rpc(method: "nvim_buf_is_valid", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_is_valid", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_del_mark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_del_mark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_mark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_set_mark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_mark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_mark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_call", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_call", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func createNamespace(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_create_namespace", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_create_namespace", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getNamespaces(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
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
          self.rpc(method: "nvim_get_namespaces", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_namespaces", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_extmark_by_id", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_extmark_by_id", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_get_extmarks", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_get_extmarks", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_extmark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_set_extmark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_del_extmark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_del_extmark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_add_highlight", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_add_highlight", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_buf_clear_namespace", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_clear_namespace", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_set_decoration_provider", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_decoration_provider", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func tabpageListWins(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Window] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_tabpage_list_wins", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_tabpage_list_wins", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_tabpage_get_var", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_tabpage_get_var", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_tabpage_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_tabpage_set_var", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_tabpage_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_tabpage_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func tabpageGetWin(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Window {
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_tabpage_get_win", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_tabpage_get_win", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func tabpageGetNumber(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_tabpage_get_number", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_tabpage_get_number", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func tabpageIsValid(
    tabpage: RxNeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
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
          self.rpc(method: "nvim_tabpage_is_valid", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_tabpage_is_valid", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_ui_attach", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_attach", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_ui_detach", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_detach", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_ui_try_resize", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_try_resize", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_ui_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_set_option", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_ui_try_resize_grid", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_try_resize_grid", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_ui_pum_set_height", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_pum_set_height", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_ui_pum_set_bounds", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_ui_pum_set_bounds", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getHlByName(
    name: String,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
        .bool(rgb),
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
          self.rpc(method: "nvim_get_hl_by_name", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_hl_by_name", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getHlById(
    hl_id: Int,
    rgb: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(hl_id)),
        .bool(rgb),
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
          self.rpc(method: "nvim_get_hl_by_id", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_hl_by_id", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getHlIdByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_hl_id_by_name", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_hl_id_by_name", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_hl", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_hl", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func feedkeys(
    keys: String,
    mode: String,
    escape_csi: Bool,
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        .string(keys),
        .string(mode),
        .bool(escape_csi),
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_feedkeys", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_feedkeys", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func input(
    keys: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(keys),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_input", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_input", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_input_mouse", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_input_mouse", params: params, expectsReturnValue: expectsReturnValue)
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

    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_replace_termcodes", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_replace_termcodes", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_exec_lua", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_exec_lua", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_notify", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_notify", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func strwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(text),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_strwidth", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_strwidth", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func listRuntimePaths(
    errWhenBlocked: Bool = true
  ) -> Single<[String]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [String] {
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_list_runtime_paths", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_list_runtime_paths", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> [String] {
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_runtime_file", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_runtime_file", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_current_dir", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_current_dir", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getCurrentLine(
    errWhenBlocked: Bool = true
  ) -> Single<String> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_current_line", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_current_line", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_current_line", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_current_line", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_del_current_line", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_del_current_line", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getVar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_var", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_var", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_var", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getVvar(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_vvar", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_vvar", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_vvar", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_vvar", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getOption(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_option", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_option", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getAllOptionsInfo(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
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
          self.rpc(method: "nvim_get_all_options_info", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_all_options_info", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getOptionInfo(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
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
          self.rpc(method: "nvim_get_option_info", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_option_info", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_option", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_echo", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_echo", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_out_write", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_out_write", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_err_write", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_err_write", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_err_writeln", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_err_writeln", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func listBufs(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Buffer]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Buffer] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Buffer(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_list_bufs", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_list_bufs", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getCurrentBuf(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Buffer {
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_current_buf", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_current_buf", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_current_buf", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_current_buf", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func listWins(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Window] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_list_wins", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_list_wins", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getCurrentWin(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Window {
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_current_win", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_current_win", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_current_win", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_current_win", params: params, expectsReturnValue: expectsReturnValue)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Buffer {
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_create_buf", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_create_buf", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_open_term", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_open_term", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_chan_send", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_chan_send", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func listTabpages(
    errWhenBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Tabpage]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Tabpage] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Tabpage(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_list_tabpages", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_list_tabpages", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getCurrentTabpage(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Tabpage {
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_current_tabpage", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_current_tabpage", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_current_tabpage", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_current_tabpage", params: params, expectsReturnValue: expectsReturnValue)
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

    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw RxNeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_paste", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_paste", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_put", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_put", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_subscribe", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_subscribe", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_unsubscribe", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_unsubscribe", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getColorByName(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_color_by_name", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_color_by_name", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getColorMap(
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
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
          self.rpc(method: "nvim_get_color_map", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_color_map", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getContext(
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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
          self.rpc(method: "nvim_get_context", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_context", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func loadContext(
    dict: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .map(dict.mapToDict({ (Value.string($0), $1) })),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_load_context", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_load_context", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getMode(
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]
    return self
      .rpc(method: "nvim_get_mode", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> [Dictionary<String, RxNeovimApi.Value>] {
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        throw RxNeovimApi.Error.conversion(type: [Dictionary<String, RxNeovimApi.Value>].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_keymap", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_keymap", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_keymap", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_keymap", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_del_keymap", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_del_keymap", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getCommands(
    opts: Dictionary<String, RxNeovimApi.Value>,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .map(opts.mapToDict({ (Value.string($0), $1) })),
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
          self.rpc(method: "nvim_get_commands", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_commands", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getApiInfo(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_api_info", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_api_info", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_set_client_info", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_set_client_info", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func getChanInfo(
    chan: Int,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(chan)),
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
          self.rpc(method: "nvim_get_chan_info", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_chan_info", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func listChans(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_list_chans", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_list_chans", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func callAtomic(
    calls: RxNeovimApi.Value,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        calls,
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_call_atomic", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_call_atomic", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func listUis(
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_list_uis", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_list_uis", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getProcChildren(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(pid)),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_proc_children", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_proc_children", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getProc(
    pid: Int,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(pid)),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_proc", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_proc", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_select_popupmenu_item", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_select_popupmenu_item", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func delMark(
    name: String,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
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
          self.rpc(method: "nvim_del_mark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_del_mark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_get_mark", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_get_mark", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_eval_statusline", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_eval_statusline", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func exec(
    src: String,
    output: Bool,
    errWhenBlocked: Bool = true
  ) -> Single<String> {

    let params: [RxNeovimApi.Value] = [
        .string(src),
        .bool(output),
    ]

    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_exec", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_exec", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_command", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_command", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func eval(
    expr: String,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        .string(expr),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_eval", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_eval", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_call_function", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_call_function", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_call_dict_function", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_call_dict_function", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_parse_expression", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_parse_expression", params: params, expectsReturnValue: true)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Window {
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_open_win", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_open_win", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_config", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_config", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func winGetConfig(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
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
          self.rpc(method: "nvim_win_get_config", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_config", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func winGetBuf(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Buffer {
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_buf", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_buf", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_buf", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_buf", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func winGetCursor(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_cursor", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_cursor", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_cursor", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_cursor", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func winGetHeight(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_height", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_height", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_height", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_height", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func winGetWidth(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_width", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_width", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_width", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_width", params: params, expectsReturnValue: expectsReturnValue)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_var", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_var", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_var", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_win_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_del_var", params: params, expectsReturnValue: expectsReturnValue)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_option", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_option", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_set_option", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  public func winGetPosition(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.int64Value == nil ? nil : Int(v.int64Value!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_position", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_position", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func winGetTabpage(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Tabpage {
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_tabpage", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_tabpage", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func winGetNumber(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.int64Value == nil ? nil : Int(value.int64Value!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_get_number", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_get_number", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func winIsValid(
    window: RxNeovimApi.Window,
    errWhenBlocked: Bool = true
  ) -> Single<Bool> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
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
          self.rpc(method: "nvim_win_is_valid", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_is_valid", params: params, expectsReturnValue: true)
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
          self.rpc(method: "nvim_win_hide", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_hide", params: params, expectsReturnValue: expectsReturnValue)
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
          self.rpc(method: "nvim_win_close", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_win_close", params: params, expectsReturnValue: expectsReturnValue)
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

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_call", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_win_call", params: params, expectsReturnValue: true)
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
