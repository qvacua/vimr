// Auto generated for nvim version 0.2.2.
// See bin/generate_api_methods.py

import Foundation
import RxMsgpackRpc
import MessagePack
import RxSwift

extension NvimApi {

  public enum Error: Swift.Error {

    private static let exceptionRawValue = UInt64(0)
    private static let validationRawValue = UInt64(1)

    case exception(message: String)
    case validation(message: String)
    case blocked
    case conversion(type: Any.Type)
    case unknown

    init(_ value: NvimApi.Value?) {
      let array = value?.arrayValue
      guard array?.count == 2 else {
        self = .unknown
        return
      }

      guard let rawValue = array?[0].unsignedIntegerValue, let message = array?[1].stringValue else {
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

public extension NvimApi {

  public func bufLineCount(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func bufGetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    checkBlocked: Bool = true
  ) -> Single<[String]> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(start)),
        .int(Int64(end)),
        .bool(strict_indexing),
    ]
    
    func transform(_ value: Value) throws -> [String] {
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
        throw NvimApi.Error.conversion(type: [String].self)
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

  public func bufSetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(start)),
        .int(Int64(end)),
        .bool(strict_indexing),
        .array(replacement.map { .string($0) }),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_lines", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_buf_set_lines", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func bufGetVar(
    buffer: NvimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func bufGetChangedtick(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func bufGetKeymap(
    buffer: NvimApi.Buffer,
    mode: String,
    checkBlocked: Bool = true
  ) -> Single<[Dictionary<String, NvimApi.Value>]> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(mode),
    ]
    
    func transform(_ value: Value) throws -> [Dictionary<String, NvimApi.Value>] {
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        throw NvimApi.Error.conversion(type: [Dictionary<String, NvimApi.Value>].self)
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

  public func bufSetVar(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_buf_set_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func bufDelVar(
    buffer: NvimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_buf_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func bufGetOption(
    buffer: NvimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func bufSetOption(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_buf_set_option", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func bufGetName(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<String> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    
    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
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

  public func bufSetName(
    buffer: NvimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_set_name", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_buf_set_name", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func bufIsValid(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> Single<Bool> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    
    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
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

  public func bufGetMark(
    buffer: NvimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<[Int]> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        throw NvimApi.Error.conversion(type: [Int].self)
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

  public func bufAddHighlight(
    buffer: NvimApi.Buffer,
    src_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .string(hl_group),
        .int(Int64(line)),
        .int(Int64(col_start)),
        .int(Int64(col_end)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func bufClearHighlight(
    buffer: NvimApi.Buffer,
    src_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .int(Int64(line_start)),
        .int(Int64(line_end)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_buf_clear_highlight", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_buf_clear_highlight", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func tabpageListWins(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> Single<[NvimApi.Window]> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    
    func transform(_ value: Value) throws -> [NvimApi.Window] {
      guard let result = (value.arrayValue?.compactMap({ v in NvimApi.Window(v) })) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Window].self)
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

  public func tabpageGetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func tabpageSetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_tabpage_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_tabpage_set_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func tabpageDelVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_tabpage_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_tabpage_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func tabpageGetWin(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Window> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Window {
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
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

  public func tabpageGetNumber(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func tabpageIsValid(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> Single<Bool> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    
    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
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

  public func uiAttach(
    width: Int,
    height: Int,
    options: Dictionary<String, NvimApi.Value>,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(width)),
        .int(Int64(height)),
        .map(options.mapToDict({ (Value.string($0), $1) })),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_ui_attach", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_ui_attach", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func uiDetach(
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_ui_detach", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_ui_detach", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func uiTryResize(
    width: Int,
    height: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(width)),
        .int(Int64(height)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_ui_try_resize", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_ui_try_resize", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func uiSetOption(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_ui_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_ui_set_option", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func command(
    command: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(command),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_command", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_command", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func getHlByName(
    name: String,
    rgb: Bool,
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, NvimApi.Value>> {
 
    let params: [NvimApi.Value] = [
        .string(name),
        .bool(rgb),
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
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, NvimApi.Value>> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(hl_id)),
        .bool(rgb),
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
          self.rpc(method: "nvim_get_hl_by_id", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }
    
    return self
      .rpc(method: "nvim_get_hl_by_id", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func feedkeys(
    keys: String,
    mode: String,
    escape_csi: Bool,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(keys),
        .string(mode),
        .bool(escape_csi),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_feedkeys", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_feedkeys", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func input(
    keys: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .string(keys),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func replaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    checkBlocked: Bool = true
  ) -> Single<String> {
 
    let params: [NvimApi.Value] = [
        .string(str),
        .bool(from_part),
        .bool(do_lt),
        .bool(special),
    ]
    
    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
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

  public func commandOutput(
    str: String,
    checkBlocked: Bool = true
  ) -> Single<String> {
 
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    
    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
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

  public func eval(
    expr: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .string(expr),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func callFunction(
    fname: String,
    args: NvimApi.Value,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .string(fname),
        args,
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func executeLua(
    code: String,
    args: NvimApi.Value,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .string(code),
        args,
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func strwidth(
    text: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .string(text),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func listRuntimePaths(
    checkBlocked: Bool = true
  ) -> Single<[String]> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> [String] {
      guard let result = (value.arrayValue?.compactMap({ v in v.stringValue })) else {
        throw NvimApi.Error.conversion(type: [String].self)
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

  public func setCurrentDir(
    dir: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(dir),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_current_dir", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_current_dir", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func getCurrentLine(
    checkBlocked: Bool = true
  ) -> Single<String> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> String {
      guard let result = (value.stringValue) else {
        throw NvimApi.Error.conversion(type: String.self)
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

  public func setCurrentLine(
    line: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(line),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_current_line", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_current_line", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func delCurrentLine(
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_del_current_line", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_del_current_line", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func getVar(
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func setVar(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func delVar(
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func getVvar(
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func getOption(
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func setOption(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_option", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func outWrite(
    str: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_out_write", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_out_write", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func errWrite(
    str: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_err_write", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_err_write", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func errWriteln(
    str: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_err_writeln", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_err_writeln", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func listBufs(
    checkBlocked: Bool = true
  ) -> Single<[NvimApi.Buffer]> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> [NvimApi.Buffer] {
      guard let result = (value.arrayValue?.compactMap({ v in NvimApi.Buffer(v) })) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Buffer].self)
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

  public func getCurrentBuf(
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Buffer> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Buffer {
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
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

  public func setCurrentBuf(
    buffer: NvimApi.Buffer,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_current_buf", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_current_buf", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func listWins(
    checkBlocked: Bool = true
  ) -> Single<[NvimApi.Window]> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> [NvimApi.Window] {
      guard let result = (value.arrayValue?.compactMap({ v in NvimApi.Window(v) })) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Window].self)
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

  public func getCurrentWin(
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Window> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Window {
      guard let result = (NvimApi.Window(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Window.self)
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

  public func setCurrentWin(
    window: NvimApi.Window,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_current_win", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_current_win", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func listTabpages(
    checkBlocked: Bool = true
  ) -> Single<[NvimApi.Tabpage]> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> [NvimApi.Tabpage] {
      guard let result = (value.arrayValue?.compactMap({ v in NvimApi.Tabpage(v) })) else {
        throw NvimApi.Error.conversion(type: [NvimApi.Tabpage].self)
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

  public func getCurrentTabpage(
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Tabpage> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Tabpage {
      guard let result = (NvimApi.Tabpage(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Tabpage.self)
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

  public func setCurrentTabpage(
    tabpage: NvimApi.Tabpage,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_set_current_tabpage", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_set_current_tabpage", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func subscribe(
    event: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(event),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_subscribe", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_subscribe", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func unsubscribe(
    event: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .string(event),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_unsubscribe", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_unsubscribe", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func getColorByName(
    name: String,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func getColorMap(
    checkBlocked: Bool = true
  ) -> Single<Dictionary<String, NvimApi.Value>> {
 
    let params: [NvimApi.Value] = [
        
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
          self.rpc(method: "nvim_get_color_map", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }
    
    return self
      .rpc(method: "nvim_get_color_map", params: params, expectsReturnValue: true)
      .map(transform)
  }

  public func getMode(
  ) -> Single<Dictionary<String, NvimApi.Value>> {
 
    let params: [NvimApi.Value] = [
        
    ]
    return self
      .rpc(method: "nvim_get_mode", params: params, expectsReturnValue: true)
      .map { value in
        guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
          throw NvimApi.Error.conversion(type: Dictionary<String, NvimApi.Value>.self)
        }

        return result
      }
  }

  public func getKeymap(
    mode: String,
    checkBlocked: Bool = true
  ) -> Single<[Dictionary<String, NvimApi.Value>]> {
 
    let params: [NvimApi.Value] = [
        .string(mode),
    ]
    
    func transform(_ value: Value) throws -> [Dictionary<String, NvimApi.Value>] {
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        throw NvimApi.Error.conversion(type: [Dictionary<String, NvimApi.Value>].self)
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

  public func getApiInfo(
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func callAtomic(
    calls: NvimApi.Value,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        calls,
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func winGetBuf(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Buffer> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Buffer {
      guard let result = (NvimApi.Buffer(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Buffer.self)
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

  public func winGetCursor(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<[Int]> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        throw NvimApi.Error.conversion(type: [Int].self)
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

  public func winSetCursor(
    window: NvimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .array(pos.map { .int(Int64($0)) }),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_set_cursor", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_win_set_cursor", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func winGetHeight(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func winSetHeight(
    window: NvimApi.Window,
    height: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .int(Int64(height)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_set_height", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_win_set_height", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func winGetWidth(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func winSetWidth(
    window: NvimApi.Window,
    width: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .int(Int64(width)),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_set_width", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_win_set_width", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func winGetVar(
    window: NvimApi.Window,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func winSetVar(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_set_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_win_set_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func winDelVar(
    window: NvimApi.Window,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_del_var", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_win_del_var", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func winGetOption(
    window: NvimApi.Window,
    name: String,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Value> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Value {
      guard let result = (Optional(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Value.self)
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

  public func winSetOption(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Single<Void> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
        value,
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "nvim_win_set_option", params: params, expectsReturnValue: expectsReturnValue)
        )
        .map { _ in () }
    } 
    
    return self
      .rpc(method: "nvim_win_set_option", params: params, expectsReturnValue: expectsReturnValue)
      .map { _ in () }
  }

  public func winGetPosition(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<[Int]> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> [Int] {
      guard let result = (value.arrayValue?.compactMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        throw NvimApi.Error.conversion(type: [Int].self)
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

  public func winGetTabpage(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<NvimApi.Tabpage> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> NvimApi.Tabpage {
      guard let result = (NvimApi.Tabpage(value)) else {
        throw NvimApi.Error.conversion(type: NvimApi.Tabpage.self)
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

  public func winGetNumber(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Int> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> Int {
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        throw NvimApi.Error.conversion(type: Int.self)
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

  public func winIsValid(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> Single<Bool> {
 
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    
    func transform(_ value: Value) throws -> Bool {
      guard let result = (value.boolValue) else {
        throw NvimApi.Error.conversion(type: Bool.self)
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

}

extension NvimApi.Buffer {

  init?(_ value: NvimApi.Value) {
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

extension NvimApi.Window {

  init?(_ value: NvimApi.Value) {
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

extension NvimApi.Tabpage {

  init?(_ value: NvimApi.Value) {
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

fileprivate func msgPackDictToSwift(_ dict: Dictionary<NvimApi.Value, NvimApi.Value>?) -> Dictionary<String, NvimApi.Value>? {
  return dict?.compactMapToDict { k, v in
    guard let strKey = k.stringValue else {
      return nil
    }

    return (strKey, v)
  }
}

fileprivate func msgPackArrayDictToSwift(_ array: [NvimApi.Value]?) -> [Dictionary<String, NvimApi.Value>]? {
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
