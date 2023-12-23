// Auto generated for nvim version 0.9.4.
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
  func getAutocmds(
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_autocmds", params: params)
      .map(transform)
  }

  func createAutocmd(
    event: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_create_autocmd", params: params)
      .map(transform)
  }

  func delAutocmd(
    id: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(id)),
    ]

    return self
      .sendRequest(method: "nvim_del_autocmd", params: params)
      .asCompletable()
  }

  func clearAutocmds(
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_clear_autocmds", params: params)
      .asCompletable()
  }

  func createAugroup(
    name: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_create_augroup", params: params)
      .map(transform)
  }

  func delAugroupById(
    id: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(id)),
    ]

    return self
      .sendRequest(method: "nvim_del_augroup_by_id", params: params)
      .asCompletable()
  }

  func delAugroupByName(
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_del_augroup_by_name", params: params)
      .asCompletable()
  }

  func execAutocmds(
    event: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      event,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_exec_autocmds", params: params)
      .asCompletable()
  }

  func bufLineCount(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_line_count", params: params)
      .map(transform)
  }

  func bufAttach(
    buffer: RxNeovimApi.Buffer,
    send_buffer: Bool,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_attach", params: params)
      .map(transform)
  }

  func bufDetach(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_detach", params: params)
      .map(transform)
  }

  func bufGetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool
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

    return self
      .sendRequest(method: "nvim_buf_get_lines", params: params)
      .map(transform)
  }

  func bufSetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    return self
      .sendRequest(method: "nvim_buf_set_lines", params: params)
      .asCompletable()
  }

  func bufSetText(
    buffer: RxNeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    replacement: [String]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .array(replacement.map { .string($0) }),
    ]

    return self
      .sendRequest(method: "nvim_buf_set_text", params: params)
      .asCompletable()
  }

  func bufGetText(
    buffer: RxNeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_get_text", params: params)
      .map(transform)
  }

  func bufGetOffset(
    buffer: RxNeovimApi.Buffer,
    index: Int
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

    return self
      .sendRequest(method: "nvim_buf_get_offset", params: params)
      .map(transform)
  }

  func bufGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "nvim_buf_get_var", params: params)
      .map(transform)
  }

  func bufGetChangedtick(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_get_changedtick", params: params)
      .map(transform)
  }

  func bufGetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String
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

    return self
      .sendRequest(method: "nvim_buf_get_keymap", params: params)
      .map(transform)
  }

  func bufSetKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_buf_set_keymap", params: params)
      .asCompletable()
  }

  func bufDelKeymap(
    buffer: RxNeovimApi.Buffer,
    mode: String,
    lhs: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
    ]

    return self
      .sendRequest(method: "nvim_buf_del_keymap", params: params)
      .asCompletable()
  }

  func bufSetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_buf_set_var", params: params)
      .asCompletable()
  }

  func bufDelVar(
    buffer: RxNeovimApi.Buffer,
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_buf_del_var", params: params)
      .asCompletable()
  }

  func bufGetName(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_get_name", params: params)
      .map(transform)
  }

  func bufSetName(
    buffer: RxNeovimApi.Buffer,
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_buf_set_name", params: params)
      .asCompletable()
  }

  func bufIsLoaded(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_is_loaded", params: params)
      .map(transform)
  }

  func bufDelete(
    buffer: RxNeovimApi.Buffer,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_buf_delete", params: params)
      .asCompletable()
  }

  func bufIsValid(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_is_valid", params: params)
      .map(transform)
  }

  func bufDelMark(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "nvim_buf_del_mark", params: params)
      .map(transform)
  }

  func bufSetMark(
    buffer: RxNeovimApi.Buffer,
    name: String,
    line: Int,
    col: Int,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_set_mark", params: params)
      .map(transform)
  }

  func bufGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "nvim_buf_get_mark", params: params)
      .map(transform)
  }

  func bufCall(
    buffer: RxNeovimApi.Buffer,
    fun: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_buf_call", params: params)
      .map(transform)
  }

  func parseCmd(
    str: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_parse_cmd", params: params)
      .map(transform)
  }

  func cmd(
    cmd: [String: RxNeovimApi.Value],
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_cmd", params: params)
      .map(transform)
  }

  func createUserCommand(
    name: String,
    command: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      command,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_create_user_command", params: params)
      .asCompletable()
  }

  func delUserCommand(
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_del_user_command", params: params)
      .asCompletable()
  }

  func bufCreateUserCommand(
    buffer: RxNeovimApi.Buffer,
    name: String,
    command: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      command,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_buf_create_user_command", params: params)
      .asCompletable()
  }

  func bufDelUserCommand(
    buffer: RxNeovimApi.Buffer,
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_buf_del_user_command", params: params)
      .asCompletable()
  }

  func getCommands(
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_commands", params: params)
      .map(transform)
  }

  func bufGetCommands(
    buffer: RxNeovimApi.Buffer,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_get_commands", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func exec(
    src: String,
    output: Bool
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

    return self
      .sendRequest(method: "nvim_exec", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func commandOutput(
    command: String
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

    return self
      .sendRequest(method: "nvim_command_output", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func executeLua(
    code: String,
    args: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_execute_lua", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufGetNumber(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "nvim_buf_get_number", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufClearHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    return self
      .sendRequest(method: "nvim_buf_clear_highlight", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufSetVirtualText(
    buffer: RxNeovimApi.Buffer,
    src_id: Int,
    line: Int,
    chunks: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_set_virtual_text", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func getHlById(
    hl_id: Int,
    rgb: Bool
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

    return self
      .sendRequest(method: "nvim_get_hl_by_id", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func getHlByName(
    name: String,
    rgb: Bool
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

    return self
      .sendRequest(method: "nvim_get_hl_by_name", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rInsert(
    buffer: RxNeovimApi.Buffer,
    lnum: Int,
    lines: [String]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(lnum)),
      .array(lines.map { .string($0) }),
    ]

    return self
      .sendRequest(method: "buffer_insert", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetLine(
    buffer: RxNeovimApi.Buffer,
    index: Int
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

    return self
      .sendRequest(method: "buffer_get_line", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rSetLine(
    buffer: RxNeovimApi.Buffer,
    index: Int,
    line: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
      .string(line),
    ]

    return self
      .sendRequest(method: "buffer_set_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rDelLine(
    buffer: RxNeovimApi.Buffer,
    index: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    return self
      .sendRequest(method: "buffer_del_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetLineSlice(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool
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

    return self
      .sendRequest(method: "buffer_get_line_slice", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rSetLineSlice(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    replacement: [String]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
      .array(replacement.map { .string($0) }),
    ]

    return self
      .sendRequest(method: "buffer_set_line_slice", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rSetVar(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "buffer_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rDelVar(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "buffer_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wSetVar(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "window_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wDelVar(
    window: RxNeovimApi.Window,
    name: String
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

    return self
      .sendRequest(method: "window_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func geSetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    value: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "tabpage_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func geDelVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String
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

    return self
      .sendRequest(method: "tabpage_del_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etVar(
    name: String,
    value: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "vim_set_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func elVar(
    name: String
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

    return self
      .sendRequest(method: "vim_del_var", params: params)
      .map(transform)
  }

  func getOptionInfo(
    name: String
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

    return self
      .sendRequest(method: "nvim_get_option_info", params: params)
      .map(transform)
  }

  func createNamespace(
    name: String
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

    return self
      .sendRequest(method: "nvim_create_namespace", params: params)
      .map(transform)
  }

  func getNamespaces(
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_namespaces", params: params)
      .map(transform)
  }

  func bufGetExtmarkById(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    id: Int,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_get_extmark_by_id", params: params)
      .map(transform)
  }

  func bufGetExtmarks(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    start: RxNeovimApi.Value,
    end: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_get_extmarks", params: params)
      .map(transform)
  }

  func bufSetExtmark(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line: Int,
    col: Int,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_buf_set_extmark", params: params)
      .map(transform)
  }

  func bufDelExtmark(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    id: Int
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

    return self
      .sendRequest(method: "nvim_buf_del_extmark", params: params)
      .map(transform)
  }

  func bufAddHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int
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

    return self
      .sendRequest(method: "nvim_buf_add_highlight", params: params)
      .map(transform)
  }

  func bufClearNamespace(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    return self
      .sendRequest(method: "nvim_buf_clear_namespace", params: params)
      .asCompletable()
  }

  func setDecorationProvider(
    ns_id: Int,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_set_decoration_provider", params: params)
      .asCompletable()
  }

  func getOptionValue(
    name: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_option_value", params: params)
      .map(transform)
  }

  func setOptionValue(
    name: String,
    value: RxNeovimApi.Value,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_set_option_value", params: params)
      .asCompletable()
  }

  func getAllOptionsInfo(
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_all_options_info", params: params)
      .map(transform)
  }

  func getOptionInfo2(
    name: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_option_info2", params: params)
      .map(transform)
  }

  func setOption(
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_set_option", params: params)
      .asCompletable()
  }

  func getOption(
    name: String
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

    return self
      .sendRequest(method: "nvim_get_option", params: params)
      .map(transform)
  }

  func bufGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "nvim_buf_get_option", params: params)
      .map(transform)
  }

  func bufSetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_buf_set_option", params: params)
      .asCompletable()
  }

  func winGetOption(
    window: RxNeovimApi.Window,
    name: String
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

    return self
      .sendRequest(method: "nvim_win_get_option", params: params)
      .map(transform)
  }

  func winSetOption(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_win_set_option", params: params)
      .asCompletable()
  }

  func tabpageListWins(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "nvim_tabpage_list_wins", params: params)
      .map(transform)
  }

  func tabpageGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String
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

    return self
      .sendRequest(method: "nvim_tabpage_get_var", params: params)
      .map(transform)
  }

  func tabpageSetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_tabpage_set_var", params: params)
      .asCompletable()
  }

  func tabpageDelVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_tabpage_del_var", params: params)
      .asCompletable()
  }

  func tabpageGetWin(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "nvim_tabpage_get_win", params: params)
      .map(transform)
  }

  func tabpageGetNumber(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "nvim_tabpage_get_number", params: params)
      .map(transform)
  }

  func tabpageIsValid(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "nvim_tabpage_is_valid", params: params)
      .map(transform)
  }

  func uiAttach(
    width: Int,
    height: Int,
    options: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .map(options.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_ui_attach", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tach(
    width: Int,
    height: Int,
    enable_rgb: Bool
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .bool(enable_rgb),
    ]

    return self
      .sendRequest(method: "ui_attach", params: params)
      .asCompletable()
  }

  func uiSetFocus(
    gained: Bool
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .bool(gained),
    ]

    return self
      .sendRequest(method: "nvim_ui_set_focus", params: params)
      .asCompletable()
  }

  func uiDetach(
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    return self
      .sendRequest(method: "nvim_ui_detach", params: params)
      .asCompletable()
  }

  func uiTryResize(
    width: Int,
    height: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    return self
      .sendRequest(method: "nvim_ui_try_resize", params: params)
      .asCompletable()
  }

  func uiSetOption(
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_ui_set_option", params: params)
      .asCompletable()
  }

  func uiTryResizeGrid(
    grid: Int,
    width: Int,
    height: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(grid)),
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    return self
      .sendRequest(method: "nvim_ui_try_resize_grid", params: params)
      .asCompletable()
  }

  func uiPumSetHeight(
    height: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(height)),
    ]

    return self
      .sendRequest(method: "nvim_ui_pum_set_height", params: params)
      .asCompletable()
  }

  func uiPumSetBounds(
    width: Float,
    height: Float,
    row: Float,
    col: Float
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .float(width),
      .float(height),
      .float(row),
      .float(col),
    ]

    return self
      .sendRequest(method: "nvim_ui_pum_set_bounds", params: params)
      .asCompletable()
  }

  func getHlIdByName(
    name: String
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

    return self
      .sendRequest(method: "nvim_get_hl_id_by_name", params: params)
      .map(transform)
  }

  func getHl(
    ns_id: Int,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_hl", params: params)
      .map(transform)
  }

  func setHl(
    ns_id: Int,
    name: String,
    val: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
      .string(name),
      .map(val.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_set_hl", params: params)
      .asCompletable()
  }

  func setHlNs(
    ns_id: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    return self
      .sendRequest(method: "nvim_set_hl_ns", params: params)
      .asCompletable()
  }

  func setHlNsFast(
    ns_id: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    return self
      .sendRequest(method: "nvim_set_hl_ns_fast", params: params)
      .asCompletable()
  }

  func feedkeys(
    keys: String,
    mode: String,
    escape_ks: Bool
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    return self
      .sendRequest(method: "nvim_feedkeys", params: params)
      .asCompletable()
  }

  func input(
    keys: String
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

    return self
      .sendRequest(method: "nvim_input", params: params)
      .map(transform)
  }

  func inputMouse(
    button: String,
    action: String,
    modifier: String,
    grid: Int,
    row: Int,
    col: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(button),
      .string(action),
      .string(modifier),
      .int(Int64(grid)),
      .int(Int64(row)),
      .int(Int64(col)),
    ]

    return self
      .sendRequest(method: "nvim_input_mouse", params: params)
      .asCompletable()
  }

  func replaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool
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

    return self
      .sendRequest(method: "nvim_replace_termcodes", params: params)
      .map(transform)
  }

  func execLua(
    code: String,
    args: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_exec_lua", params: params)
      .map(transform)
  }

  func notify(
    msg: String,
    log_level: Int,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_notify", params: params)
      .map(transform)
  }

  func strwidth(
    text: String
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

    return self
      .sendRequest(method: "nvim_strwidth", params: params)
      .map(transform)
  }

  func listRuntimePaths(
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_list_runtime_paths", params: params)
      .map(transform)
  }

  func getRuntimeFile(
    name: String,
    all: Bool
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

    return self
      .sendRequest(method: "nvim_get_runtime_file", params: params)
      .map(transform)
  }

  func setCurrentDir(
    dir: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(dir),
    ]

    return self
      .sendRequest(method: "nvim_set_current_dir", params: params)
      .asCompletable()
  }

  func getCurrentLine(
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_current_line", params: params)
      .map(transform)
  }

  func setCurrentLine(
    line: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(line),
    ]

    return self
      .sendRequest(method: "nvim_set_current_line", params: params)
      .asCompletable()
  }

  func delCurrentLine(
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    return self
      .sendRequest(method: "nvim_del_current_line", params: params)
      .asCompletable()
  }

  func getVar(
    name: String
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

    return self
      .sendRequest(method: "nvim_get_var", params: params)
      .map(transform)
  }

  func setVar(
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_set_var", params: params)
      .asCompletable()
  }

  func delVar(
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_del_var", params: params)
      .asCompletable()
  }

  func getVvar(
    name: String
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

    return self
      .sendRequest(method: "nvim_get_vvar", params: params)
      .map(transform)
  }

  func setVvar(
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_set_vvar", params: params)
      .asCompletable()
  }

  func echo(
    chunks: RxNeovimApi.Value,
    history: Bool,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      chunks,
      .bool(history),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_echo", params: params)
      .asCompletable()
  }

  func outWrite(
    str: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    return self
      .sendRequest(method: "nvim_out_write", params: params)
      .asCompletable()
  }

  func errWrite(
    str: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    return self
      .sendRequest(method: "nvim_err_write", params: params)
      .asCompletable()
  }

  func errWriteln(
    str: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    return self
      .sendRequest(method: "nvim_err_writeln", params: params)
      .asCompletable()
  }

  func listBufs(
  ) -> Single<[RxNeovimApi.Buffer]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Buffer(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Buffer].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_list_bufs", params: params)
      .map(transform)
  }

  func getCurrentBuf(
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_current_buf", params: params)
      .map(transform)
  }

  func setCurrentBuf(
    buffer: RxNeovimApi.Buffer
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    return self
      .sendRequest(method: "nvim_set_current_buf", params: params)
      .asCompletable()
  }

  func listWins(
  ) -> Single<[RxNeovimApi.Window]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Window(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_list_wins", params: params)
      .map(transform)
  }

  func getCurrentWin(
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_current_win", params: params)
      .map(transform)
  }

  func setCurrentWin(
    window: RxNeovimApi.Window
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    return self
      .sendRequest(method: "nvim_set_current_win", params: params)
      .asCompletable()
  }

  func createBuf(
    listed: Bool,
    scratch: Bool
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

    return self
      .sendRequest(method: "nvim_create_buf", params: params)
      .map(transform)
  }

  func openTerm(
    buffer: RxNeovimApi.Buffer,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_open_term", params: params)
      .map(transform)
  }

  func chanSend(
    chan: Int,
    data: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(chan)),
      .string(data),
    ]

    return self
      .sendRequest(method: "nvim_chan_send", params: params)
      .asCompletable()
  }

  func listTabpages(
  ) -> Single<[RxNeovimApi.Tabpage]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Tabpage(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Tabpage].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_list_tabpages", params: params)
      .map(transform)
  }

  func getCurrentTabpage(
  ) -> Single<RxNeovimApi.Tabpage> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Tabpage in
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_current_tabpage", params: params)
      .map(transform)
  }

  func setCurrentTabpage(
    tabpage: RxNeovimApi.Tabpage
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    return self
      .sendRequest(method: "nvim_set_current_tabpage", params: params)
      .asCompletable()
  }

  func paste(
    data: String,
    crlf: Bool,
    phase: Int
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

    return self
      .sendRequest(method: "nvim_paste", params: params)
      .map(transform)
  }

  func put(
    lines: [String],
    type: String,
    after: Bool,
    follow: Bool
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .array(lines.map { .string($0) }),
      .string(type),
      .bool(after),
      .bool(follow),
    ]

    return self
      .sendRequest(method: "nvim_put", params: params)
      .asCompletable()
  }

  func subscribe(
    event: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    return self
      .sendRequest(method: "nvim_subscribe", params: params)
      .asCompletable()
  }

  func unsubscribe(
    event: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    return self
      .sendRequest(method: "nvim_unsubscribe", params: params)
      .asCompletable()
  }

  func getColorByName(
    name: String
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

    return self
      .sendRequest(method: "nvim_get_color_by_name", params: params)
      .map(transform)
  }

  func getColorMap(
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_color_map", params: params)
      .map(transform)
  }

  func getContext(
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_context", params: params)
      .map(transform)
  }

  func loadContext(
    dict: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_load_context", params: params)
      .map(transform)
  }

  func getMode(
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

  func getKeymap(
    mode: String
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

    return self
      .sendRequest(method: "nvim_get_keymap", params: params)
      .map(transform)
  }

  func setKeymap(
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_set_keymap", params: params)
      .asCompletable()
  }

  func delKeymap(
    mode: String,
    lhs: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(mode),
      .string(lhs),
    ]

    return self
      .sendRequest(method: "nvim_del_keymap", params: params)
      .asCompletable()
  }

  func getApiInfo(
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_get_api_info", params: params)
      .map(transform)
  }

  func setClientInfo(
    name: String,
    version: [String: RxNeovimApi.Value],
    type: String,
    methods: [String: RxNeovimApi.Value],
    attributes: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      .map(version.mapToDict { (Value.string($0), $1) }),
      .string(type),
      .map(methods.mapToDict { (Value.string($0), $1) }),
      .map(attributes.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_set_client_info", params: params)
      .asCompletable()
  }

  func getChanInfo(
    chan: Int
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

    return self
      .sendRequest(method: "nvim_get_chan_info", params: params)
      .map(transform)
  }

  func listChans(
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_list_chans", params: params)
      .map(transform)
  }

  func callAtomic(
    calls: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_call_atomic", params: params)
      .map(transform)
  }

  func listUis(
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    return self
      .sendRequest(method: "nvim_list_uis", params: params)
      .map(transform)
  }

  func getProcChildren(
    pid: Int
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

    return self
      .sendRequest(method: "nvim_get_proc_children", params: params)
      .map(transform)
  }

  func getProc(
    pid: Int
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

    return self
      .sendRequest(method: "nvim_get_proc", params: params)
      .map(transform)
  }

  func selectPopupmenuItem(
    item: Int,
    insert: Bool,
    finish: Bool,
    opts: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(item)),
      .bool(insert),
      .bool(finish),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_select_popupmenu_item", params: params)
      .asCompletable()
  }

  func delMark(
    name: String
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

    return self
      .sendRequest(method: "nvim_del_mark", params: params)
      .map(transform)
  }

  func getMark(
    name: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_get_mark", params: params)
      .map(transform)
  }

  func evalStatusline(
    str: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_eval_statusline", params: params)
      .map(transform)
  }

  func exec2(
    src: String,
    opts: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_exec2", params: params)
      .map(transform)
  }

  func command(
    command: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(command),
    ]

    return self
      .sendRequest(method: "nvim_command", params: params)
      .asCompletable()
  }

  func eval(
    expr: String
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

    return self
      .sendRequest(method: "nvim_eval", params: params)
      .map(transform)
  }

  func callFunction(
    fn: String,
    args: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_call_function", params: params)
      .map(transform)
  }

  func callDictFunction(
    dict: RxNeovimApi.Value,
    fn: String,
    args: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_call_dict_function", params: params)
      .map(transform)
  }

  func parseExpression(
    expr: String,
    flags: String,
    highlight: Bool
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

    return self
      .sendRequest(method: "nvim_parse_expression", params: params)
      .map(transform)
  }

  func openWin(
    buffer: RxNeovimApi.Buffer,
    enter: Bool,
    config: [String: RxNeovimApi.Value]
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

    return self
      .sendRequest(method: "nvim_open_win", params: params)
      .map(transform)
  }

  func winSetConfig(
    window: RxNeovimApi.Window,
    config: [String: RxNeovimApi.Value]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .map(config.mapToDict { (Value.string($0), $1) }),
    ]

    return self
      .sendRequest(method: "nvim_win_set_config", params: params)
      .asCompletable()
  }

  func winGetConfig(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_config", params: params)
      .map(transform)
  }

  func winGetBuf(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_buf", params: params)
      .map(transform)
  }

  func winSetBuf(
    window: RxNeovimApi.Window,
    buffer: RxNeovimApi.Buffer
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(buffer.handle)),
    ]

    return self
      .sendRequest(method: "nvim_win_set_buf", params: params)
      .asCompletable()
  }

  func winGetCursor(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_cursor", params: params)
      .map(transform)
  }

  func winSetCursor(
    window: RxNeovimApi.Window,
    pos: [Int]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    return self
      .sendRequest(method: "nvim_win_set_cursor", params: params)
      .asCompletable()
  }

  func winGetHeight(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_height", params: params)
      .map(transform)
  }

  func winSetHeight(
    window: RxNeovimApi.Window,
    height: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    return self
      .sendRequest(method: "nvim_win_set_height", params: params)
      .asCompletable()
  }

  func winGetWidth(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_width", params: params)
      .map(transform)
  }

  func winSetWidth(
    window: RxNeovimApi.Window,
    width: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    return self
      .sendRequest(method: "nvim_win_set_width", params: params)
      .asCompletable()
  }

  func winGetVar(
    window: RxNeovimApi.Window,
    name: String
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

    return self
      .sendRequest(method: "nvim_win_get_var", params: params)
      .map(transform)
  }

  func winSetVar(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "nvim_win_set_var", params: params)
      .asCompletable()
  }

  func winDelVar(
    window: RxNeovimApi.Window,
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    return self
      .sendRequest(method: "nvim_win_del_var", params: params)
      .asCompletable()
  }

  func winGetPosition(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_position", params: params)
      .map(transform)
  }

  func winGetTabpage(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_tabpage", params: params)
      .map(transform)
  }

  func winGetNumber(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_get_number", params: params)
      .map(transform)
  }

  func winIsValid(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "nvim_win_is_valid", params: params)
      .map(transform)
  }

  func winHide(
    window: RxNeovimApi.Window
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    return self
      .sendRequest(method: "nvim_win_hide", params: params)
      .asCompletable()
  }

  func winClose(
    window: RxNeovimApi.Window,
    force: Bool
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .bool(force),
    ]

    return self
      .sendRequest(method: "nvim_win_close", params: params)
      .asCompletable()
  }

  func winCall(
    window: RxNeovimApi.Window,
    fun: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "nvim_win_call", params: params)
      .map(transform)
  }

  func winSetHlNs(
    window: RxNeovimApi.Window,
    ns_id: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(ns_id)),
    ]

    return self
      .sendRequest(method: "nvim_win_set_hl_ns", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rLineCount(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "buffer_line_count", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool
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

    return self
      .sendRequest(method: "buffer_get_lines", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rSetLines(
    buffer: RxNeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    return self
      .sendRequest(method: "buffer_set_lines", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetVar(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "buffer_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetName(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "buffer_get_name", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rSetName(
    buffer: RxNeovimApi.Buffer,
    name: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    return self
      .sendRequest(method: "buffer_set_name", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rIsValid(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "buffer_is_valid", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetMark(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "buffer_get_mark", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func ommandOutput(
    command: String
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

    return self
      .sendRequest(method: "vim_command_output", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetNumber(
    buffer: RxNeovimApi.Buffer
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

    return self
      .sendRequest(method: "buffer_get_number", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rClearHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    return self
      .sendRequest(method: "buffer_clear_highlight", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rAddHighlight(
    buffer: RxNeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int
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

    return self
      .sendRequest(method: "buffer_add_highlight", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etOption(
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "vim_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etOption(
    name: String
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

    return self
      .sendRequest(method: "vim_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rGetOption(
    buffer: RxNeovimApi.Buffer,
    name: String
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

    return self
      .sendRequest(method: "buffer_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rSetOption(
    buffer: RxNeovimApi.Buffer,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "buffer_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetOption(
    window: RxNeovimApi.Window,
    name: String
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

    return self
      .sendRequest(method: "window_get_option", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wSetOption(
    window: RxNeovimApi.Window,
    name: String,
    value: RxNeovimApi.Value
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    return self
      .sendRequest(method: "window_set_option", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func geGetWindows(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "tabpage_get_windows", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func geGetVar(
    tabpage: RxNeovimApi.Tabpage,
    name: String
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

    return self
      .sendRequest(method: "tabpage_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func geGetWindow(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "tabpage_get_window", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func geIsValid(
    tabpage: RxNeovimApi.Tabpage
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

    return self
      .sendRequest(method: "tabpage_is_valid", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tach(
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    return self
      .sendRequest(method: "ui_detach", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func yResize(
    width: Int,
    height: Int
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

    return self
      .sendRequest(method: "ui_try_resize", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func eedkeys(
    keys: String,
    mode: String,
    escape_ks: Bool
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    return self
      .sendRequest(method: "vim_feedkeys", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nput(
    keys: String
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

    return self
      .sendRequest(method: "vim_input", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func eplaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool
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

    return self
      .sendRequest(method: "vim_replace_termcodes", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func trwidth(
    text: String
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

    return self
      .sendRequest(method: "vim_strwidth", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func istRuntimePaths(
  ) -> Single<[String]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw RxNeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_list_runtime_paths", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func hangeDirectory(
    dir: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(dir),
    ]

    return self
      .sendRequest(method: "vim_change_directory", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentLine(
  ) -> Single<String> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> String in
      guard let result = (value.stringValue) else {
        throw RxNeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_current_line", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentLine(
    line: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(line),
    ]

    return self
      .sendRequest(method: "vim_set_current_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func elCurrentLine(
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
    ]

    return self
      .sendRequest(method: "vim_del_current_line", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etVar(
    name: String
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

    return self
      .sendRequest(method: "vim_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etVvar(
    name: String
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

    return self
      .sendRequest(method: "vim_get_vvar", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func utWrite(
    str: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    return self
      .sendRequest(method: "vim_out_write", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func rrWrite(
    str: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    return self
      .sendRequest(method: "vim_err_write", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func eportError(
    str: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(str),
    ]

    return self
      .sendRequest(method: "vim_report_error", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etBuffers(
  ) -> Single<[RxNeovimApi.Buffer]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Buffer(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Buffer].self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_buffers", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentBuffer(
  ) -> Single<RxNeovimApi.Buffer> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Buffer in
      guard let result = (RxNeovimApi.Buffer(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Buffer.self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_current_buffer", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentBuffer(
    buffer: RxNeovimApi.Buffer
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    return self
      .sendRequest(method: "vim_set_current_buffer", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etWindows(
  ) -> Single<[RxNeovimApi.Window]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Window(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Window].self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_windows", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentWindow(
  ) -> Single<RxNeovimApi.Window> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Window in
      guard let result = (RxNeovimApi.Window(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Window.self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_current_window", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentWindow(
    window: RxNeovimApi.Window
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    return self
      .sendRequest(method: "vim_set_current_window", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etTabpages(
  ) -> Single<[RxNeovimApi.Tabpage]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [RxNeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in RxNeovimApi.Tabpage(v) }) else {
        throw RxNeovimApi.Error.conversion(type: [RxNeovimApi.Tabpage].self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_tabpages", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentTabpage(
  ) -> Single<RxNeovimApi.Tabpage> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Tabpage in
      guard let result = (RxNeovimApi.Tabpage(value)) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Tabpage.self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_current_tabpage", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etCurrentTabpage(
    tabpage: RxNeovimApi.Tabpage
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    return self
      .sendRequest(method: "vim_set_current_tabpage", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func ubscribe(
    event: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    return self
      .sendRequest(method: "vim_subscribe", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nsubscribe(
    event: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(event),
    ]

    return self
      .sendRequest(method: "vim_unsubscribe", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func ameToColor(
    name: String
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

    return self
      .sendRequest(method: "vim_name_to_color", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etColorMap(
  ) -> Single<[String: RxNeovimApi.Value]> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> [String: RxNeovimApi.Value] in
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        throw RxNeovimApi.Error.conversion(type: [String: RxNeovimApi.Value].self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_color_map", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func etApiInfo(
  ) -> Single<RxNeovimApi.Value> {
    let params: [RxNeovimApi.Value] = [
    ]

    let transform = { (_ value: Value) throws -> RxNeovimApi.Value in
      guard let result = Optional(value) else {
        throw RxNeovimApi.Error.conversion(type: RxNeovimApi.Value.self)
      }

      return result
    }

    return self
      .sendRequest(method: "vim_get_api_info", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func ommand(
    command: String
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .string(command),
    ]

    return self
      .sendRequest(method: "vim_command", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func val(
    expr: String
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

    return self
      .sendRequest(method: "vim_eval", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func allFunction(
    fn: String,
    args: RxNeovimApi.Value
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

    return self
      .sendRequest(method: "vim_call_function", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetBuffer(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "window_get_buffer", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetCursor(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "window_get_cursor", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wSetCursor(
    window: RxNeovimApi.Window,
    pos: [Int]
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    return self
      .sendRequest(method: "window_set_cursor", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetHeight(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "window_get_height", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wSetHeight(
    window: RxNeovimApi.Window,
    height: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    return self
      .sendRequest(method: "window_set_height", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetWidth(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "window_get_width", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wSetWidth(
    window: RxNeovimApi.Window,
    width: Int
  ) -> Completable {
    let params: [RxNeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    return self
      .sendRequest(method: "window_set_width", params: params)
      .asCompletable()
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetVar(
    window: RxNeovimApi.Window,
    name: String
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

    return self
      .sendRequest(method: "window_get_var", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetPosition(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "window_get_position", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wGetTabpage(
    window: RxNeovimApi.Window
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

    return self
      .sendRequest(method: "window_get_tabpage", params: params)
      .map(transform)
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func wIsValid(
    window: RxNeovimApi.Window
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
