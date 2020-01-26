// Auto generated for nvim version 0.4.3.
// See bin/generate_api_methods.py

import Foundation
import MessagePack
import RxSwift

extension RxNeovimApi {

  public enum Error: Swift.Error {

    private static let exceptionRawValue = UInt64(0)
    private static let validationRawValue = UInt64(1)

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

  func bufLineCount(
    buffer: RxNeovimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func bufAttach(
    buffer: RxNeovimApi.Buffer,
    send_buffer: Bool,
    opts: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufDetach(
    buffer: RxNeovimApi.Buffer,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufGetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufSetLines(
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

  func bufGetOffset(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(index)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func bufGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufGetChangedtick(
    buffer: RxNeovimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func bufGetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufSetKeymap(
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

  func bufDelKeymap(
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

  func bufGetCommands(
    buffer: RxNeovimApi.Buffer,
    opts: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufSetVar(
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

  func bufDelVar(
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

  func bufGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufSetOption(
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

  func bufGetName(
    buffer: RxNeovimApi.Buffer,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufSetName(
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

  func bufIsLoaded(
    buffer: RxNeovimApi.Buffer,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufIsValid(
    buffer: RxNeovimApi.Buffer,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func bufGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if checkBlocked {
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

  func bufAddHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    checkBlocked: Bool = true
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
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func bufClearNamespace(
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

  func bufClearHighlight(
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
          self.rpc(method: "nvim_buf_clear_highlight", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    }

    return self
      .rpc(method: "nvim_buf_clear_highlight", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }

  func bufSetVirtualText(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line: Int,
    chunks: RxNeovimApi.Value,
    opts: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(ns_id)),
        .int(Int64(line)),
        chunks,
        .map(opts.mapToDict({ (Value.string($0), $1) })),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_virtual_text", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_buf_set_virtual_text", params: params, expectsReturnValue: true)
      .map(transform)
  }

  func tabpageListWins(
    tabpage: RxNeovimApi.Tabpage,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func tabpageGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func tabpageSetVar(
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

  func tabpageDelVar(
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

  func tabpageGetWin(
    tabpage: RxNeovimApi.Tabpage,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func tabpageGetNumber(
    tabpage: RxNeovimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func tabpageIsValid(
    tabpage: RxNeovimApi.Tabpage,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func uiAttach(
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

  func uiDetach(
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

  func uiTryResize(
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

  func uiSetOption(
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

  func uiTryResizeGrid(
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

  func uiPumSetHeight(
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

  func command(
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

  func getHlByName(
    name: String,
    rgb: Bool,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func getHlById(
    hl_id: Int,
    rgb: Bool,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func feedkeys(
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

  func input(
    keys: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(keys),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func inputMouse(
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

  func replaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func commandOutput(
    command: String,
    checkBlocked: Bool = true
  ) -> Single<String> {

    let params: [RxNeovimApi.Value] = [
        .string(command),
    ]

    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_command_output", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_command_output", params: params, expectsReturnValue: true)
      .map(transform)
  }

  func eval(
    expr: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func executeLua(
    code: String,
    args: RxNeovimApi.Value,
    checkBlocked: Bool = true
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

    if checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_execute_lua", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }

    return self
      .rpc(method: "nvim_execute_lua", params: params, expectsReturnValue: true)
      .map(transform)
  }

  func callFunction(
    fn: String,
    args: RxNeovimApi.Value,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func callDictFunction(
    dict: RxNeovimApi.Value,
    fn: String,
    args: RxNeovimApi.Value,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func strwidth(
    text: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(text),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func listRuntimePaths(
    checkBlocked: Bool = true
  ) -> Single<[String]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [String] {
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if checkBlocked {
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

  func setCurrentDir(
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

  func getCurrentLine(
    checkBlocked: Bool = true
  ) -> Single<String> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if checkBlocked {
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

  func setCurrentLine(
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

  func delCurrentLine(
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

  func getVar(
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func setVar(
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

  func delVar(
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

  func getVvar(
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func setVvar(
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

  func getOption(
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func setOption(
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

  func outWrite(
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

  func errWrite(
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

  func errWriteln(
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

  func listBufs(
    checkBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Buffer]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Buffer] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Buffer(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Buffer].self)
      }

      return result
    }

    if checkBlocked {
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

  func getCurrentBuf(
    checkBlocked: Bool = true
  ) -> Single<RxNeovimApi.Buffer> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Buffer {
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    if checkBlocked {
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

  func setCurrentBuf(
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

  func listWins(
    checkBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Window]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Window] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Window(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    if checkBlocked {
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

  func getCurrentWin(
    checkBlocked: Bool = true
  ) -> Single<RxNeovimApi.Window> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Window {
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    if checkBlocked {
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

  func setCurrentWin(
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

  func createBuf(
    listed: Bool,
    scratch: Bool,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func openWin(
    buffer: RxNeovimApi.Buffer,
    enter: Bool,
    config: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func listTabpages(
    checkBlocked: Bool = true
  ) -> Single<[RxNeovimApi.Tabpage]> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> [RxNeovimApi.Tabpage] {
      guard let result = (value.arrayValue?.compactMap({ v in RxNeovimApi.Tabpage(v) })) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Tabpage].self)
      }

      return result
    }

    if checkBlocked {
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

  func getCurrentTabpage(
    checkBlocked: Bool = true
  ) -> Single<RxNeovimApi.Tabpage> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Tabpage {
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    if checkBlocked {
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

  func setCurrentTabpage(
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

  func createNamespace(
    name: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func getNamespaces(
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
      }

      return result
    }

    if checkBlocked {
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

  func paste(
    data: String,
    crlf: Bool,
    phase: Int,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func put(
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

  func subscribe(
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

  func unsubscribe(
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

  func getColorByName(
    name: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .string(name),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func getColorMap(
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, RxNeovimApi.Value>> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> Dictionary<String, RxNeovimApi.Value> {
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        throw RxNeovimApi.Error.conversion(type: Dictionary<String, RxNeovimApi.Value>.self)
      }

      return result
    }

    if checkBlocked {
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

  func getContext(
    opts: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func loadContext(
    dict: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func getMode(
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

  func getKeymap(
    mode: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func setKeymap(
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

  func delKeymap(
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

  func getCommands(
    opts: Dictionary<String, RxNeovimApi.Value>,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func getApiInfo(
    checkBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if checkBlocked {
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

  func setClientInfo(
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

  func getChanInfo(
    chan: Int,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func listChans(
    checkBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if checkBlocked {
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

  func callAtomic(
    calls: RxNeovimApi.Value,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func parseExpression(
    expr: String,
    flags: String,
    highlight: Bool,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func listUis(
    checkBlocked: Bool = true
  ) -> Single<RxNeovimApi.Value> {

    let params: [RxNeovimApi.Value] = [
        
    ]

    func transform(_ value: Value) throws -> RxNeovimApi.Value {
      guard let result = (Optional(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    if checkBlocked {
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

  func getProcChildren(
    pid: Int,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func getProc(
    pid: Int,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func selectPopupmenuItem(
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

  func winGetBuf(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func winSetBuf(
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

  func winGetCursor(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if checkBlocked {
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

  func winSetCursor(
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

  func winGetHeight(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func winSetHeight(
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

  func winGetWidth(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func winSetWidth(
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

  func winGetVar(
    window: RxNeovimApi.Window,
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func winSetVar(
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

  func winDelVar(
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

  func winGetOption(
    window: RxNeovimApi.Window,
    name: String,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func winSetOption(
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

  func winGetPosition(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<[Int]> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        throw RxNeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if checkBlocked {
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

  func winGetTabpage(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func winGetNumber(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Int> {

    let params: [RxNeovimApi.Value] = [
        .int(Int64(window.handle)),
    ]

    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw RxNeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if checkBlocked {
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

  func winIsValid(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func winSetConfig(
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

  func winGetConfig(
    window: RxNeovimApi.Window,
    checkBlocked: Bool = true
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

    if checkBlocked {
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

  func winClose(
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

}

extension RxNeovimApi.Buffer {

  init?(_ value: RxNeovimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == 0 else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.integerValue else {
      return nil
    }

    self.handle = Int(handle)
  }
}

extension RxNeovimApi.Window {

  init?(_ value: RxNeovimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == 1 else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.integerValue else {
      return nil
    }

    self.handle = Int(handle)
  }
}

extension RxNeovimApi.Tabpage {

  init?(_ value: RxNeovimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == 2 else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.integerValue else {
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
