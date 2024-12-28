// Auto generated for nvim version 0.10.3.
// See bin/generate_api_methods.py

import Foundation
import MessagePack

public extension NeovimApi {
  enum Error: Swift.Error {
    public static let exceptionRawValue = UInt64(0)
    public static let validationRawValue = UInt64(1)

    case exception(message: String)
    case validation(message: String)
    case blocked
    case conversion(type: Any.Type)
    case other(cause: Swift.Error)
    case unknown

    init(_ value: NeovimApi.Value?) {
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

public extension NeovimApi {
  func nvimGetAutocmds(
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_autocmds", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateAutocmd(
    event: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      event,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_create_autocmd", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelAutocmd(
    id: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(id)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_autocmd", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimClearAutocmds(
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_clear_autocmds", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateAugroup(
    name: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_create_augroup", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelAugroupById(
    id: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(id)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_augroup_by_id", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelAugroupByName(
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_augroup_by_name", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimExecAutocmds(
    event: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      event,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_exec_autocmds", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufLineCount(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_line_count", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufAttach(
    buffer: NeovimApi.Buffer,
    send_buffer: Bool,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .bool(send_buffer),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_attach", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDetach(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_detach", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetLines(
    buffer: NeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    errWhenBlocked: Bool = true
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_lines", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetLines(
    buffer: NeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_lines", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetText(
    buffer: NeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_text", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetText(
    buffer: NeovimApi.Buffer,
    start_row: Int,
    start_col: Int,
    end_row: Int,
    end_col: Int,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start_row)),
      .int(Int64(start_col)),
      .int(Int64(end_row)),
      .int(Int64(end_col)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_text", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetOffset(
    buffer: NeovimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_offset", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetVar(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetChangedtick(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_changedtick", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetKeymap(
    buffer: NeovimApi.Buffer,
    mode: String,
    errWhenBlocked: Bool = true
  ) async -> Result<[[String: NeovimApi.Value]], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [[String: NeovimApi.Value]] in
        guard let result = msgPackArrayDictToSwift(value.arrayValue) else {
          throw NeovimApi.Error.conversion(type: [[String: NeovimApi.Value]].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_keymap", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [[String: NeovimApi.Value]] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetKeymap(
    buffer: NeovimApi.Buffer,
    mode: String,
    lhs: String,
    rhs: String,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelKeymap(
    buffer: NeovimApi.Buffer,
    mode: String,
    lhs: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(mode),
      .string(lhs),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_del_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetVar(
    buffer: NeovimApi.Buffer,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelVar(
    buffer: NeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetName(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetName(
    buffer: NeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_name", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufIsLoaded(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_is_loaded", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelete(
    buffer: NeovimApi.Buffer,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_delete", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufIsValid(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelMark(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_del_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetMark(
    buffer: NeovimApi.Buffer,
    name: String,
    line: Int,
    col: Int,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      .int(Int64(line)),
      .int(Int64(col)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetMark(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufCall(
    buffer: NeovimApi.Buffer,
    fun: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      fun,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_call", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimParseCmd(
    str: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_parse_cmd", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCmd(
    cmd: [String: NeovimApi.Value],
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(cmd.mapToDict { (Value.string($0), $1) }),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_cmd", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateUserCommand(
    name: String,
    command: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      command,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_create_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelUserCommand(
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufCreateUserCommand(
    buffer: NeovimApi.Buffer,
    name: String,
    command: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      command,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_create_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelUserCommand(
    buffer: NeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_del_user_command", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCommands(
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_commands", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetCommands(
    buffer: NeovimApi.Buffer,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_commands", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
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
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(src),
      .bool(output),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_exec", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
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
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(command),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_command_output", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimExecuteLua(
    code: String,
    args: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(code),
      args,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_execute_lua", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufGetNumber(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufClearHighlight(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_clear_highlight", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufSetVirtualText(
    buffer: NeovimApi.Buffer,
    src_id: Int,
    line: Int,
    chunks: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(src_id)),
      .int(Int64(line)),
      chunks,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_virtual_text", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
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
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(hl_id)),
      .bool(rgb),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_hl_by_id", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
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
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .bool(rgb),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_hl_by_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferInsert(
    buffer: NeovimApi.Buffer,
    lnum: Int,
    lines: [String],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(lnum)),
      .array(lines.map { .string($0) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_insert", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLine(
    buffer: NeovimApi.Buffer,
    index: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_line", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLine(
    buffer: NeovimApi.Buffer,
    index: Int,
    line: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
      .string(line),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_set_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferDelLine(
    buffer: NeovimApi.Buffer,
    index: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(index)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_del_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLineSlice(
    buffer: NeovimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    errWhenBlocked: Bool = true
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_line_slice", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLineSlice(
    buffer: NeovimApi.Buffer,
    start: Int,
    end: Int,
    include_start: Bool,
    include_end: Bool,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(include_start),
      .bool(include_end),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_set_line_slice", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetVar(
    buffer: NeovimApi.Buffer,
    name: String,
    value: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferDelVar(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetVar(
    window: NeovimApi.Window,
    name: String,
    value: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowDelVar(
    window: NeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageSetVar(
    tabpage: NeovimApi.Tabpage,
    name: String,
    value: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "tabpage_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageDelVar(
    tabpage: NeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "tabpage_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetVar(
    name: String,
    value: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_set_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_del_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
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
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_option_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimSetOption(
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_option", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufGetOption(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimBufSetOption(
    buffer: NeovimApi.Buffer,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimWinGetOption(
    window: NeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimWinSetOption(
    window: NeovimApi.Window,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func nvimCallAtomic(
    calls: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      calls,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_call_atomic", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCreateNamespace(
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_create_namespace", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetNamespaces(
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_namespaces", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetExtmarkById(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    id: Int,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_extmark_by_id", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufGetExtmarks(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    start: NeovimApi.Value,
    end: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      start,
      end,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_get_extmarks", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufSetExtmark(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    line: Int,
    col: Int,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line)),
      .int(Int64(col)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_set_extmark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufDelExtmark(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    id: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(id)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_del_extmark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufAddHighlight(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .string(hl_group),
      .int(Int64(line)),
      .int(Int64(col_start)),
      .int(Int64(col_end)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_add_highlight", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimBufClearNamespace(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_buf_clear_namespace", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetDecorationProvider(
    ns_id: Int,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_decoration_provider", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetOptionValue(
    name: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_option_value", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetOptionValue(
    name: String,
    value: NeovimApi.Value,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_option_value", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetAllOptionsInfo(
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_all_options_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetOptionInfo2(
    name: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_option_info2", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageListWins(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<[NeovimApi.Window], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Window(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_list_wins", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageGetVar(
    tabpage: NeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageSetVar(
    tabpage: NeovimApi.Tabpage,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageDelVar(
    tabpage: NeovimApi.Tabpage,
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageGetWin(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Window, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Window in
      guard let result = (NeovimApi.Window(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_get_win", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageSetWin(
    tabpage: NeovimApi.Tabpage,
    win: NeovimApi.Window,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .int(Int64(win.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_set_win", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageGetNumber(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimTabpageIsValid(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_tabpage_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiAttach(
    width: Int,
    height: Int,
    options: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .map(options.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_attach", params: params)
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
    enable_rgb: Bool,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
      .bool(enable_rgb),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "ui_attach", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiSetFocus(
    gained: Bool,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .bool(gained),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_set_focus", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiDetach(
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_detach", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiTryResize(
    width: Int,
    height: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_try_resize", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiSetOption(
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_set_option", params: params)
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
    height: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(grid)),
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_try_resize_grid", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiPumSetHeight(
    height: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_pum_set_height", params: params)
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
    col: Float,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .float(width),
      .float(height),
      .float(row),
      .float(col),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_pum_set_bounds", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUiTermEvent(
    event: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(event),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_ui_term_event", params: params)
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
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_hl_id_by_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetHl(
    ns_id: Int,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(ns_id)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_hl", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetHl(
    ns_id: Int,
    name: String,
    val: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(ns_id)),
      .string(name),
      .map(val.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_hl", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetHlNs(
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_hl_ns", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetHlNs(
    ns_id: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_hl_ns", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetHlNsFast(
    ns_id: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(ns_id)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_hl_ns_fast", params: params)
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
    escape_ks: Bool,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_feedkeys", params: params)
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
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(keys),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_input", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
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
    col: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(button),
      .string(action),
      .string(modifier),
      .int(Int64(grid)),
      .int(Int64(row)),
      .int(Int64(col)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_input_mouse", params: params)
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
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
      .bool(from_part),
      .bool(do_lt),
      .bool(special),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_replace_termcodes", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimExecLua(
    code: String,
    args: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(code),
      args,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_exec_lua", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimNotify(
    msg: String,
    log_level: Int,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(msg),
      .int(Int64(log_level)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_notify", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimStrwidth(
    text: String,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(text),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_strwidth", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListRuntimePaths(
    errWhenBlocked: Bool = true
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_list_runtime_paths", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
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
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .bool(all),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_runtime_file", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentDir(
    dir: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(dir),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_current_dir", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentLine(
    errWhenBlocked: Bool = true
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_current_line", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentLine(
    line: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(line),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_current_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelCurrentLine(
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_current_line", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetVar(
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelVar(
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_var", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_vvar", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetVvar(
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_vvar", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimEcho(
    chunks: NeovimApi.Value,
    history: Bool,
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      chunks,
      .bool(history),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_echo", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimOutWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_out_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimErrWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_err_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimErrWriteln(
    str: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_err_writeln", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListBufs(
    errWhenBlocked: Bool = true
  ) async -> Result<[NeovimApi.Buffer], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Buffer(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_list_bufs", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Buffer] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentBuf(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Buffer, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Buffer in
      guard let result = (NeovimApi.Buffer(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_current_buf", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentBuf(
    buffer: NeovimApi.Buffer,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_current_buf", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListWins(
    errWhenBlocked: Bool = true
  ) async -> Result<[NeovimApi.Window], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Window(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_list_wins", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentWin(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Window, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Window in
      guard let result = (NeovimApi.Window(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_current_win", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentWin(
    window: NeovimApi.Window,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_current_win", params: params)
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
  ) async -> Result<NeovimApi.Buffer, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .bool(listed),
      .bool(scratch),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Buffer in
      guard let result = (NeovimApi.Buffer(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_create_buf", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimOpenTerm(
    buffer: NeovimApi.Buffer,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_open_term", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimChanSend(
    chan: Int,
    data: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(chan)),
      .string(data),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_chan_send", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListTabpages(
    errWhenBlocked: Bool = true
  ) async -> Result<[NeovimApi.Tabpage], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Tabpage(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_list_tabpages", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Tabpage] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetCurrentTabpage(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Tabpage, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Tabpage in
      guard let result = (NeovimApi.Tabpage(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_current_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetCurrentTabpage(
    tabpage: NeovimApi.Tabpage,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_current_tabpage", params: params)
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
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(data),
      .bool(crlf),
      .int(Int64(phase)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_paste", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
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
    follow: Bool,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .array(lines.map { .string($0) }),
      .string(type),
      .bool(after),
      .bool(follow),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_put", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_subscribe", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimUnsubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_unsubscribe", params: params)
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
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_color_by_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetColorMap(
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_color_map", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetContext(
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_context", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimLoadContext(
    dict: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .map(dict.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_load_context", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetMode(
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let reqResult = await self.sendRequest(method: "nvim_get_mode", params: params)
    switch reqResult {
    case let .success(value):
      guard let result = msgPackDictToSwift(value.dictionaryValue) else {
        return .failure(Error.conversion(type: [String: NeovimApi.Value].self))
      }
      return .success(result)

    case let .failure(error):
      return .failure(error)
    }
  }

  func nvimGetKeymap(
    mode: String,
    errWhenBlocked: Bool = true
  ) async -> Result<[[String: NeovimApi.Value]], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(mode),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [[String: NeovimApi.Value]] in
        guard let result = msgPackArrayDictToSwift(value.arrayValue) else {
          throw NeovimApi.Error.conversion(type: [[String: NeovimApi.Value]].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_keymap", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [[String: NeovimApi.Value]] in
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
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(mode),
      .string(lhs),
      .string(rhs),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimDelKeymap(
    mode: String,
    lhs: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(mode),
      .string(lhs),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_keymap", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetApiInfo(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_api_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimSetClientInfo(
    name: String,
    version: [String: NeovimApi.Value],
    type: String,
    methods: [String: NeovimApi.Value],
    attributes: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .map(version.mapToDict { (Value.string($0), $1) }),
      .string(type),
      .map(methods.mapToDict { (Value.string($0), $1) }),
      .map(attributes.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_set_client_info", params: params)
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
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(chan)),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_chan_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListChans(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_list_chans", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimListUis(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_list_uis", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetProcChildren(
    pid: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(pid)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_proc_children", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetProc(
    pid: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(pid)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_proc", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
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
    opts: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(item)),
      .bool(insert),
      .bool(finish),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_select_popupmenu_item", params: params)
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
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_del_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimGetMark(
    name: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_get_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimEvalStatusline(
    str: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_eval_statusline", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimExec2(
    src: String,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(src),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_exec2", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCommand(
    command: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(command),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_command", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(expr),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_eval", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCallFunction(
    fn: String,
    args: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(fn),
      args,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_call_function", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimCallDictFunction(
    dict: NeovimApi.Value,
    fn: String,
    args: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      dict,
      .string(fn),
      args,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_call_dict_function", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
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
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(expr),
      .string(flags),
      .bool(highlight),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_parse_expression", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimOpenWin(
    buffer: NeovimApi.Buffer,
    enter: Bool,
    config: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Window, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .bool(enter),
      .map(config.mapToDict { (Value.string($0), $1) }),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Window in
      guard let result = (NeovimApi.Window(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_open_win", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetConfig(
    window: NeovimApi.Window,
    config: [String: NeovimApi.Value],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .map(config.mapToDict { (Value.string($0), $1) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_config", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetConfig(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_config", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetBuf(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Buffer, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Buffer in
      guard let result = (NeovimApi.Buffer(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_buf", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetBuf(
    window: NeovimApi.Window,
    buffer: NeovimApi.Buffer,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(buffer.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_buf", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetCursor(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_cursor", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetCursor(
    window: NeovimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_cursor", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetHeight(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_height", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetHeight(
    window: NeovimApi.Window,
    height: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_height", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetWidth(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_width", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetWidth(
    window: NeovimApi.Window,
    width: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_width", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetVar(
    window: NeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetVar(
    window: NeovimApi.Window,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinDelVar(
    window: NeovimApi.Window,
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_del_var", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetPosition(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_position", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetTabpage(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Tabpage, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Tabpage in
      guard let result = (NeovimApi.Tabpage(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinGetNumber(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinIsValid(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinHide(
    window: NeovimApi.Window,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_hide", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinClose(
    window: NeovimApi.Window,
    force: Bool,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .bool(force),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_close", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinCall(
    window: NeovimApi.Window,
    fun: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      fun,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_call", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinSetHlNs(
    window: NeovimApi.Window,
    ns_id: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(ns_id)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_set_hl_ns", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  func nvimWinTextHeight(
    window: NeovimApi.Window,
    opts: [String: NeovimApi.Value],
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .map(opts.mapToDict { (Value.string($0), $1) }),
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "nvim_win_text_height", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferLineCount(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_line_count", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetLines(
    buffer: NeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    errWhenBlocked: Bool = true
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_lines", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetLines(
    buffer: NeovimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(start)),
      .int(Int64(end)),
      .bool(strict_indexing),
      .array(replacement.map { .string($0) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_set_lines", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetVar(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetName(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_name", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetName(
    buffer: NeovimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_set_name", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferIsValid(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetMark(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_mark", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
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
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(command),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_command_output", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetNumber(
    buffer: NeovimApi.Buffer,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_number", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferClearHighlight(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .int(Int64(line_start)),
      .int(Int64(line_end)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_clear_highlight", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetOption(
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_set_option", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferGetOption(
    buffer: NeovimApi.Buffer,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferSetOption(
    buffer: NeovimApi.Buffer,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetOption(
    window: NeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_option", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetOption(
    window: NeovimApi.Window,
    name: String,
    value: NeovimApi.Value,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
      value,
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_set_option", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func bufferAddHighlight(
    buffer: NeovimApi.Buffer,
    ns_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
      .int(Int64(ns_id)),
      .string(hl_group),
      .int(Int64(line)),
      .int(Int64(col_start)),
      .int(Int64(col_end)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "buffer_add_highlight", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetWindows(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<[NeovimApi.Window], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Window(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "tabpage_get_windows", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetVar(
    tabpage: NeovimApi.Tabpage,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "tabpage_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageGetWindow(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Window, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Window in
      guard let result = (NeovimApi.Window(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "tabpage_get_window", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func tabpageIsValid(
    tabpage: NeovimApi.Tabpage,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "tabpage_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func uiDetach(
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "ui_detach", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(width)),
      .int(Int64(height)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "ui_try_resize", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
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
    escape_ks: Bool,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(keys),
      .string(mode),
      .bool(escape_ks),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_feedkeys", params: params)
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
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(keys),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_input", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
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
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
      .bool(from_part),
      .bool(do_lt),
      .bool(special),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_replace_termcodes", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
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
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(text),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_strwidth", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimListRuntimePaths(
    errWhenBlocked: Bool = true
  ) async -> Result<[String], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String] in
      guard let result = (value.arrayValue?.compactMap { v in v.stringValue }) else {
        throw NeovimApi.Error.conversion(type: [String].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_list_runtime_paths", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimChangeDirectory(
    dir: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(dir),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_change_directory", params: params)
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
  ) async -> Result<String, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> String in
      guard let result = (value.stringValue) else {
        throw NeovimApi.Error.conversion(type: String.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_current_line", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> String in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentLine(
    line: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(line),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_set_current_line", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimDelCurrentLine(
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_del_current_line", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_vvar", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimOutWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_out_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimErrWrite(
    str: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_err_write", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimReportError(
    str: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(str),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_report_error", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetBuffers(
    errWhenBlocked: Bool = true
  ) async -> Result<[NeovimApi.Buffer], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Buffer] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Buffer(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Buffer].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_buffers", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Buffer] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentBuffer(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Buffer, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Buffer in
      guard let result = (NeovimApi.Buffer(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_current_buffer", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentBuffer(
    buffer: NeovimApi.Buffer,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(buffer.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_set_current_buffer", params: params)
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
  ) async -> Result<[NeovimApi.Window], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Window] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Window(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Window].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_windows", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Window] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentWindow(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Window, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Window in
      guard let result = (NeovimApi.Window(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Window.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_current_window", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Window in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentWindow(
    window: NeovimApi.Window,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_set_current_window", params: params)
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
  ) async -> Result<[NeovimApi.Tabpage], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [NeovimApi.Tabpage] in
      guard let result = (value.arrayValue?.compactMap { v in NeovimApi.Tabpage(v) }) else {
        throw NeovimApi.Error.conversion(type: [NeovimApi.Tabpage].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_tabpages", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [NeovimApi.Tabpage] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetCurrentTabpage(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Tabpage, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Tabpage in
      guard let result = (NeovimApi.Tabpage(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_current_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSetCurrentTabpage(
    tabpage: NeovimApi.Tabpage,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(tabpage.handle)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_set_current_tabpage", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimSubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_subscribe", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimUnsubscribe(
    event: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(event),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_unsubscribe", params: params)
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
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_name_to_color", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetColorMap(
    errWhenBlocked: Bool = true
  ) async -> Result<[String: NeovimApi.Value], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform =
      { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        guard let result = msgPackDictToSwift(value.dictionaryValue) else {
          throw NeovimApi.Error.conversion(type: [String: NeovimApi.Value].self)
        }

        return result
      }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_color_map", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [String: NeovimApi.Value] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimGetApiInfo(
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_get_api_info", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCommand(
    command: String,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(command),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_command", params: params)
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
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(expr),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_eval", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func vimCallFunction(
    fn: String,
    args: NeovimApi.Value,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .string(fn),
      args,
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "vim_call_function", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetBuffer(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Buffer, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Buffer in
      guard let result = (NeovimApi.Buffer(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Buffer.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_buffer", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Buffer in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetCursor(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_cursor", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetCursor(
    window: NeovimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .array(pos.map { .int(Int64($0)) }),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_set_cursor", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetHeight(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_height", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetHeight(
    window: NeovimApi.Window,
    height: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(height)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_set_height", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetWidth(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Int, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Int in
      guard let result = (value.int64Value == nil ? nil : Int(value.int64Value!)) else {
        throw NeovimApi.Error.conversion(type: Int.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_width", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Int in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowSetWidth(
    window: NeovimApi.Window,
    width: Int,
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .int(Int64(width)),
    ]

    if expectsReturnValue {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_set_width", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetVar(
    window: NeovimApi.Window,
    name: String,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Value, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
      .string(name),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Value in
      guard let result = Optional(value) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Value.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_var", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Value in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetPosition(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<[Int], NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> [Int] in
      guard let result = (value.arrayValue?.compactMap { v in
        v.int64Value == nil ? nil : Int(v.int64Value!)
      })
      else {
        throw NeovimApi.Error.conversion(type: [Int].self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_position", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> [Int] in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowGetTabpage(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<NeovimApi.Tabpage, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> NeovimApi.Tabpage in
      guard let result = (NeovimApi.Tabpage(value)) else {
        throw NeovimApi.Error.conversion(type: NeovimApi.Tabpage.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_get_tabpage", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> NeovimApi.Tabpage in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }

  @available(*, deprecated, message: "This method has been deprecated.")
  func windowIsValid(
    window: NeovimApi.Window,
    errWhenBlocked: Bool = true
  ) async -> Result<Bool, NeovimApi.Error> {
    let params: [NeovimApi.Value] = [
      .int(Int64(window.handle)),
    ]

    let transform = { (_ value: NeovimApi.Value) throws(NeovimApi.Error) -> Bool in
      guard let result = (value.boolValue) else {
        throw NeovimApi.Error.conversion(type: Bool.self)
      }

      return result
    }

    if errWhenBlocked {
      let blockedResult = await self.isBlocked()
      switch blockedResult {
      case let .success(blocked):
        if blocked { return .failure(.blocked) }
      case let .failure(error):
        return .failure(.other(cause: error))
      }
    }

    let reqResult = await self.sendRequest(method: "window_is_valid", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NeovimApi.Error) -> Bool in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }
}

public extension NeovimApi.Buffer {
  init?(_ value: NeovimApi.Value) {
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

public extension NeovimApi.Window {
  init?(_ value: NeovimApi.Value) {
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

public extension NeovimApi.Tabpage {
  init?(_ value: NeovimApi.Value) {
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

private func msgPackDictToSwift(_ dict: [NeovimApi.Value: NeovimApi.Value]?)
  -> [String: NeovimApi.Value]?
{
  dict?.compactMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

private func msgPackArrayDictToSwift(_ array: [NeovimApi.Value]?) -> [[String: NeovimApi.Value]]? {
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
