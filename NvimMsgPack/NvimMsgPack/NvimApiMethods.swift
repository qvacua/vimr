// Auto generated for nvim version 0.2.2.
// See bin/generate_api_methods.py

import MsgPackRpc
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

    // array([uint(0), string(Wrong number of arguments: expecting 2 but got 0)])
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
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    let response = self.rpc(method: "nvim_buf_line_count", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func bufGetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[String]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(start)),
        .int(Int64(end)),
        .bool(strict_indexing),
    ]
    let response = self.rpc(method: "nvim_buf_get_lines", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in v.stringValue })) else {
      return .failure(NvimApi.Error.conversion(type: [String].self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func bufSetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(start)),
        .int(Int64(end)),
        .bool(strict_indexing),
        .array(replacement.map { .string($0) }),
    ]
    let response = self.rpc(method: "nvim_buf_set_lines", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func bufGetVar(
    buffer: NvimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_buf_get_var", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func bufGetChangedtick(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    let response = self.rpc(method: "nvim_buf_get_changedtick", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func bufGetKeymap(
    buffer: NvimApi.Buffer,
    mode: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[Dictionary<String, NvimApi.Value>]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(mode),
    ]
    let response = self.rpc(method: "nvim_buf_get_keymap", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
      return .failure(NvimApi.Error.conversion(type: [Dictionary<String, NvimApi.Value>].self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func bufSetVar(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_buf_set_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func bufDelVar(
    buffer: NvimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_buf_del_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func bufGetOption(
    buffer: NvimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_buf_get_option", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func bufSetOption(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_buf_set_option", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func bufGetName(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<String> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    let response = self.rpc(method: "nvim_buf_get_name", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.stringValue) else {
      return .failure(NvimApi.Error.conversion(type: String.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func bufSetName(
    buffer: NvimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_buf_set_name", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func bufIsValid(
    buffer: NvimApi.Buffer,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Bool> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    let response = self.rpc(method: "nvim_buf_is_valid", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.boolValue) else {
      return .failure(NvimApi.Error.conversion(type: Bool.self))
    }
    
    return .success(result)
  }

  public func bufGetMark(
    buffer: NvimApi.Buffer,
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[Int]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_buf_get_mark", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
      return .failure(NvimApi.Error.conversion(type: [Int].self))
    }
    
    return .success(result)
  }

  public func bufAddHighlight(
    buffer: NvimApi.Buffer,
    src_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .string(hl_group),
        .int(Int64(line)),
        .int(Int64(col_start)),
        .int(Int64(col_end)),
    ]
    let response = self.rpc(method: "nvim_buf_add_highlight", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func bufClearHighlight(
    buffer: NvimApi.Buffer,
    src_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .int(Int64(line_start)),
        .int(Int64(line_end)),
    ]
    let response = self.rpc(method: "nvim_buf_clear_highlight", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func tabpageListWins(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[NvimApi.Window]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    let response = self.rpc(method: "nvim_tabpage_list_wins", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Window(v) })) else {
      return .failure(NvimApi.Error.conversion(type: [NvimApi.Window].self))
    }
    
    return .success(result)
  }

  public func tabpageGetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_tabpage_get_var", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func tabpageSetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_tabpage_set_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func tabpageDelVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_tabpage_del_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func tabpageGetWin(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Window> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    let response = self.rpc(method: "nvim_tabpage_get_win", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (NvimApi.Window(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Window.self))
    }
    
    return .success(result)
  }

  public func tabpageGetNumber(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    let response = self.rpc(method: "nvim_tabpage_get_number", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func tabpageIsValid(
    tabpage: NvimApi.Tabpage,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Bool> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    let response = self.rpc(method: "nvim_tabpage_is_valid", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.boolValue) else {
      return .failure(NvimApi.Error.conversion(type: Bool.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func uiAttach(
    width: Int,
    height: Int,
    options: Dictionary<String, NvimApi.Value>,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(width)),
        .int(Int64(height)),
        .map(options.mapToDict({ (Value.string($0), $1) })),
    ]
    let response = self.rpc(method: "nvim_ui_attach", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func uiDetach(
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_ui_detach", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func uiTryResize(
    width: Int,
    height: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(width)),
        .int(Int64(height)),
    ]
    let response = self.rpc(method: "nvim_ui_try_resize", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func uiSetOption(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_ui_set_option", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func command(
    command: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(command),
    ]
    let response = self.rpc(method: "nvim_command", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func getHlByName(
    name: String,
    rgb: Bool,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Dictionary<String, NvimApi.Value>> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(name),
        .bool(rgb),
    ]
    let response = self.rpc(method: "nvim_get_hl_by_name", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
      return .failure(NvimApi.Error.conversion(type: Dictionary<String, NvimApi.Value>.self))
    }
    
    return .success(result)
  }

  public func getHlById(
    hl_id: Int,
    rgb: Bool,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Dictionary<String, NvimApi.Value>> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(hl_id)),
        .bool(rgb),
    ]
    let response = self.rpc(method: "nvim_get_hl_by_id", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
      return .failure(NvimApi.Error.conversion(type: Dictionary<String, NvimApi.Value>.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func feedkeys(
    keys: String,
    mode: String,
    escape_csi: Bool,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(keys),
        .string(mode),
        .bool(escape_csi),
    ]
    let response = self.rpc(method: "nvim_feedkeys", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func input(
    keys: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(keys),
    ]
    let response = self.rpc(method: "nvim_input", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func replaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<String> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(str),
        .bool(from_part),
        .bool(do_lt),
        .bool(special),
    ]
    let response = self.rpc(method: "nvim_replace_termcodes", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.stringValue) else {
      return .failure(NvimApi.Error.conversion(type: String.self))
    }
    
    return .success(result)
  }

  public func commandOutput(
    str: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<String> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    let response = self.rpc(method: "nvim_command_output", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.stringValue) else {
      return .failure(NvimApi.Error.conversion(type: String.self))
    }
    
    return .success(result)
  }

  public func eval(
    expr: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(expr),
    ]
    let response = self.rpc(method: "nvim_eval", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func callFunction(
    fname: String,
    args: NvimApi.Value,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(fname),
        args,
    ]
    let response = self.rpc(method: "nvim_call_function", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func executeLua(
    code: String,
    args: NvimApi.Value,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(code),
        args,
    ]
    let response = self.rpc(method: "nvim_execute_lua", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func strwidth(
    text: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(text),
    ]
    let response = self.rpc(method: "nvim_strwidth", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func listRuntimePaths(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[String]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_list_runtime_paths", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in v.stringValue })) else {
      return .failure(NvimApi.Error.conversion(type: [String].self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setCurrentDir(
    dir: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(dir),
    ]
    let response = self.rpc(method: "nvim_set_current_dir", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func getCurrentLine(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<String> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_current_line", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.stringValue) else {
      return .failure(NvimApi.Error.conversion(type: String.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setCurrentLine(
    line: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(line),
    ]
    let response = self.rpc(method: "nvim_set_current_line", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func delCurrentLine(
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_del_current_line", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func getVar(
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    let response = self.rpc(method: "nvim_get_var", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setVar(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_set_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func delVar(
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    let response = self.rpc(method: "nvim_del_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func getVvar(
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    let response = self.rpc(method: "nvim_get_vvar", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func getOption(
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    let response = self.rpc(method: "nvim_get_option", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setOption(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_set_option", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func outWrite(
    str: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    let response = self.rpc(method: "nvim_out_write", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func errWrite(
    str: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    let response = self.rpc(method: "nvim_err_write", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func errWriteln(
    str: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(str),
    ]
    let response = self.rpc(method: "nvim_err_writeln", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func listBufs(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[NvimApi.Buffer]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_list_bufs", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Buffer(v) })) else {
      return .failure(NvimApi.Error.conversion(type: [NvimApi.Buffer].self))
    }
    
    return .success(result)
  }

  public func getCurrentBuf(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Buffer> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_current_buf", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (NvimApi.Buffer(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Buffer.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setCurrentBuf(
    buffer: NvimApi.Buffer,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(buffer.handle)),
    ]
    let response = self.rpc(method: "nvim_set_current_buf", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func listWins(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[NvimApi.Window]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_list_wins", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Window(v) })) else {
      return .failure(NvimApi.Error.conversion(type: [NvimApi.Window].self))
    }
    
    return .success(result)
  }

  public func getCurrentWin(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Window> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_current_win", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (NvimApi.Window(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Window.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setCurrentWin(
    window: NvimApi.Window,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_set_current_win", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func listTabpages(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[NvimApi.Tabpage]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_list_tabpages", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Tabpage(v) })) else {
      return .failure(NvimApi.Error.conversion(type: [NvimApi.Tabpage].self))
    }
    
    return .success(result)
  }

  public func getCurrentTabpage(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Tabpage> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_current_tabpage", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (NvimApi.Tabpage(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Tabpage.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func setCurrentTabpage(
    tabpage: NvimApi.Tabpage,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(tabpage.handle)),
    ]
    let response = self.rpc(method: "nvim_set_current_tabpage", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func subscribe(
    event: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(event),
    ]
    let response = self.rpc(method: "nvim_subscribe", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func unsubscribe(
    event: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .string(event),
    ]
    let response = self.rpc(method: "nvim_unsubscribe", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func getColorByName(
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(name),
    ]
    let response = self.rpc(method: "nvim_get_color_by_name", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func getColorMap(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Dictionary<String, NvimApi.Value>> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_color_map", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
      return .failure(NvimApi.Error.conversion(type: Dictionary<String, NvimApi.Value>.self))
    }
    
    return .success(result)
  }

  public func getMode(
  ) -> NvimApi.Response<Dictionary<String, NvimApi.Value>> {
 
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_mode", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
      return .failure(NvimApi.Error.conversion(type: Dictionary<String, NvimApi.Value>.self))
    }
    
    return .success(result)
  }

  public func getKeymap(
    mode: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[Dictionary<String, NvimApi.Value>]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .string(mode),
    ]
    let response = self.rpc(method: "nvim_get_keymap", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
      return .failure(NvimApi.Error.conversion(type: [Dictionary<String, NvimApi.Value>].self))
    }
    
    return .success(result)
  }

  public func getApiInfo(
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        
    ]
    let response = self.rpc(method: "nvim_get_api_info", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func callAtomic(
    calls: NvimApi.Value,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        calls,
    ]
    let response = self.rpc(method: "nvim_call_atomic", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  public func winGetBuf(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Buffer> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_buf", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (NvimApi.Buffer(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Buffer.self))
    }
    
    return .success(result)
  }

  public func winGetCursor(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[Int]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_cursor", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
      return .failure(NvimApi.Error.conversion(type: [Int].self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func winSetCursor(
    window: NvimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .array(pos.map { .int(Int64($0)) }),
    ]
    let response = self.rpc(method: "nvim_win_set_cursor", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func winGetHeight(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_height", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func winSetHeight(
    window: NvimApi.Window,
    height: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .int(Int64(height)),
    ]
    let response = self.rpc(method: "nvim_win_set_height", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func winGetWidth(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_width", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func winSetWidth(
    window: NvimApi.Window,
    width: Int,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .int(Int64(width)),
    ]
    let response = self.rpc(method: "nvim_win_set_width", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func winGetVar(
    window: NvimApi.Window,
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_win_get_var", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func winSetVar(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_win_set_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  @discardableResult
  public func winDelVar(
    window: NvimApi.Window,
    name: String,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_win_del_var", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func winGetOption(
    window: NvimApi.Window,
    name: String,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Value> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
    ]
    let response = self.rpc(method: "nvim_win_get_option", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (Optional(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Value.self))
    }
    
    return .success(result)
  }

  @discardableResult
  public func winSetOption(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Void> {
 
    if expectsReturnValue && checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }
      
      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
  
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
        .string(name),
        value,
    ]
    let response = self.rpc(method: "nvim_win_set_option", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }

  public func winGetPosition(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<[Int]> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_position", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.arrayValue?.flatMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
      return .failure(NvimApi.Error.conversion(type: [Int].self))
    }
    
    return .success(result)
  }

  public func winGetTabpage(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<NvimApi.Tabpage> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_tabpage", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (NvimApi.Tabpage(value)) else {
      return .failure(NvimApi.Error.conversion(type: NvimApi.Tabpage.self))
    }
    
    return .success(result)
  }

  public func winGetNumber(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Int> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_get_number", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
      return .failure(NvimApi.Error.conversion(type: Int.self))
    }
    
    return .success(result)
  }

  public func winIsValid(
    window: NvimApi.Window,
    checkBlocked: Bool = true
  ) -> NvimApi.Response<Bool> {
 
    if checkBlocked {
      guard let blocked = self.getMode().value?["blocking"]?.boolValue else {
        return .failure(NvimApi.Error.blocked)
      }

      if blocked {
        return .failure(NvimApi.Error.blocked)
      }
    }
    
    let params: [NvimApi.Value] = [
        .int(Int64(window.handle)),
    ]
    let response = self.rpc(method: "nvim_win_is_valid", params: params, expectsReturnValue: true)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (value.boolValue) else {
      return .failure(NvimApi.Error.conversion(type: Bool.self))
    }
    
    return .success(result)
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

  fileprivate func mapToDict<K, V>(_ transform: ((key: Key, value: Value)) throws -> (K, V)) rethrows -> Dictionary<K, V> {
    let array = try self.map(transform)
    return tuplesToDict(array)
  }

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

extension StreamApi {
  
    public func bufLineCount(
    buffer: NvimApi.Buffer
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
      ]
      let response = self.session.rpc(method: "nvim_buf_line_count", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufGetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool
  ) -> Single<[String]> {
  
    return Single<[String]>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .int(Int64(start)),
        .int(Int64(end)),
        .bool(strict_indexing),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_lines", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in v.stringValue })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufSetLines(
    buffer: NvimApi.Buffer,
    start: Int,
    end: Int,
    strict_indexing: Bool,
    replacement: [String],
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .int(Int64(start)),
        .int(Int64(end)),
        .bool(strict_indexing),
        .array(replacement.map { .string($0) }),
      ]
      let response = self.session.rpc(method: "nvim_buf_set_lines", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func bufGetVar(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_var", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufGetChangedtick(
    buffer: NvimApi.Buffer
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_changedtick", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufGetKeymap(
    buffer: NvimApi.Buffer,
    mode: String
  ) -> Single<[Dictionary<String, NvimApi.Value>]> {
  
    return Single<[Dictionary<String, NvimApi.Value>]>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(mode),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_keymap", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufSetVar(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_buf_set_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func bufDelVar(
    buffer: NvimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_buf_del_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func bufGetOption(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_option", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufSetOption(
    buffer: NvimApi.Buffer,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_buf_set_option", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func bufGetName(
    buffer: NvimApi.Buffer
  ) -> Single<String> {
  
    return Single<String>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_name", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.stringValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufSetName(
    buffer: NvimApi.Buffer,
    name: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_buf_set_name", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func bufIsValid(
    buffer: NvimApi.Buffer
  ) -> Single<Bool> {
  
    return Single<Bool>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
      ]
      let response = self.session.rpc(method: "nvim_buf_is_valid", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.boolValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufGetMark(
    buffer: NvimApi.Buffer,
    name: String
  ) -> Single<[Int]> {
  
    return Single<[Int]>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_buf_get_mark", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufAddHighlight(
    buffer: NvimApi.Buffer,
    src_id: Int,
    hl_group: String,
    line: Int,
    col_start: Int,
    col_end: Int
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .string(hl_group),
        .int(Int64(line)),
        .int(Int64(col_start)),
        .int(Int64(col_end)),
      ]
      let response = self.session.rpc(method: "nvim_buf_add_highlight", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func bufClearHighlight(
    buffer: NvimApi.Buffer,
    src_id: Int,
    line_start: Int,
    line_end: Int,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
        .int(Int64(src_id)),
        .int(Int64(line_start)),
        .int(Int64(line_end)),
      ]
      let response = self.session.rpc(method: "nvim_buf_clear_highlight", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func tabpageListWins(
    tabpage: NvimApi.Tabpage
  ) -> Single<[NvimApi.Window]> {
  
    return Single<[NvimApi.Window]>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
      ]
      let response = self.session.rpc(method: "nvim_tabpage_list_wins", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Window(v) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func tabpageGetVar(
    tabpage: NvimApi.Tabpage,
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_tabpage_get_var", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func tabpageSetVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
        .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_tabpage_set_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func tabpageDelVar(
    tabpage: NvimApi.Tabpage,
    name: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_tabpage_del_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func tabpageGetWin(
    tabpage: NvimApi.Tabpage
  ) -> Single<NvimApi.Window> {
  
    return Single<NvimApi.Window>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
      ]
      let response = self.session.rpc(method: "nvim_tabpage_get_win", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (NvimApi.Window(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func tabpageGetNumber(
    tabpage: NvimApi.Tabpage
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
      ]
      let response = self.session.rpc(method: "nvim_tabpage_get_number", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func tabpageIsValid(
    tabpage: NvimApi.Tabpage
  ) -> Single<Bool> {
  
    return Single<Bool>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
      ]
      let response = self.session.rpc(method: "nvim_tabpage_is_valid", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.boolValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func uiAttach(
    width: Int,
    height: Int,
    options: Dictionary<String, NvimApi.Value>,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(width)),
        .int(Int64(height)),
        .map(options.mapToDict({ (Value.string($0), $1) })),
      ]
      let response = self.session.rpc(method: "nvim_ui_attach", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func uiDetach(
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_ui_detach", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func uiTryResize(
    width: Int,
    height: Int,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(width)),
        .int(Int64(height)),
      ]
      let response = self.session.rpc(method: "nvim_ui_try_resize", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func uiSetOption(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_ui_set_option", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func command(
    command: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(command),
      ]
      let response = self.session.rpc(method: "nvim_command", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func getHlByName(
    name: String,
    rgb: Bool
  ) -> Single<Dictionary<String, NvimApi.Value>> {
  
    return Single<Dictionary<String, NvimApi.Value>>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
        .bool(rgb),
      ]
      let response = self.session.rpc(method: "nvim_get_hl_by_name", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getHlById(
    hl_id: Int,
    rgb: Bool
  ) -> Single<Dictionary<String, NvimApi.Value>> {
  
    return Single<Dictionary<String, NvimApi.Value>>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(hl_id)),
        .bool(rgb),
      ]
      let response = self.session.rpc(method: "nvim_get_hl_by_id", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func feedkeys(
    keys: String,
    mode: String,
    escape_csi: Bool,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(keys),
        .string(mode),
        .bool(escape_csi),
      ]
      let response = self.session.rpc(method: "nvim_feedkeys", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func input(
    keys: String
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .string(keys),
      ]
      let response = self.session.rpc(method: "nvim_input", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func replaceTermcodes(
    str: String,
    from_part: Bool,
    do_lt: Bool,
    special: Bool
  ) -> Single<String> {
  
    return Single<String>.create { single in
      let params: [NvimApi.Value] = [
          .string(str),
        .bool(from_part),
        .bool(do_lt),
        .bool(special),
      ]
      let response = self.session.rpc(method: "nvim_replace_termcodes", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.stringValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func commandOutput(
    str: String
  ) -> Single<String> {
  
    return Single<String>.create { single in
      let params: [NvimApi.Value] = [
          .string(str),
      ]
      let response = self.session.rpc(method: "nvim_command_output", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.stringValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func eval(
    expr: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .string(expr),
      ]
      let response = self.session.rpc(method: "nvim_eval", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func callFunction(
    fname: String,
    args: NvimApi.Value
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .string(fname),
        args,
      ]
      let response = self.session.rpc(method: "nvim_call_function", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func executeLua(
    code: String,
    args: NvimApi.Value
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .string(code),
        args,
      ]
      let response = self.session.rpc(method: "nvim_execute_lua", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func strwidth(
    text: String
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .string(text),
      ]
      let response = self.session.rpc(method: "nvim_strwidth", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func listRuntimePaths(
  ) -> Single<[String]> {
  
    return Single<[String]>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_list_runtime_paths", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in v.stringValue })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setCurrentDir(
    dir: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(dir),
      ]
      let response = self.session.rpc(method: "nvim_set_current_dir", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func getCurrentLine(
  ) -> Single<String> {
  
    return Single<String>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_current_line", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.stringValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setCurrentLine(
    line: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(line),
      ]
      let response = self.session.rpc(method: "nvim_set_current_line", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func delCurrentLine(
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_del_current_line", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func getVar(
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
      ]
      let response = self.session.rpc(method: "nvim_get_var", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setVar(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_set_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func delVar(
    name: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
      ]
      let response = self.session.rpc(method: "nvim_del_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func getVvar(
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
      ]
      let response = self.session.rpc(method: "nvim_get_vvar", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getOption(
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
      ]
      let response = self.session.rpc(method: "nvim_get_option", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setOption(
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_set_option", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func outWrite(
    str: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(str),
      ]
      let response = self.session.rpc(method: "nvim_out_write", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func errWrite(
    str: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(str),
      ]
      let response = self.session.rpc(method: "nvim_err_write", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func errWriteln(
    str: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(str),
      ]
      let response = self.session.rpc(method: "nvim_err_writeln", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func listBufs(
  ) -> Single<[NvimApi.Buffer]> {
  
    return Single<[NvimApi.Buffer]>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_list_bufs", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Buffer(v) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getCurrentBuf(
  ) -> Single<NvimApi.Buffer> {
  
    return Single<NvimApi.Buffer>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_current_buf", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (NvimApi.Buffer(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setCurrentBuf(
    buffer: NvimApi.Buffer,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(buffer.handle)),
      ]
      let response = self.session.rpc(method: "nvim_set_current_buf", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func listWins(
  ) -> Single<[NvimApi.Window]> {
  
    return Single<[NvimApi.Window]>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_list_wins", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Window(v) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getCurrentWin(
  ) -> Single<NvimApi.Window> {
  
    return Single<NvimApi.Window>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_current_win", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (NvimApi.Window(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setCurrentWin(
    window: NvimApi.Window,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_set_current_win", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func listTabpages(
  ) -> Single<[NvimApi.Tabpage]> {
  
    return Single<[NvimApi.Tabpage]>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_list_tabpages", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in NvimApi.Tabpage(v) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getCurrentTabpage(
  ) -> Single<NvimApi.Tabpage> {
  
    return Single<NvimApi.Tabpage>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_current_tabpage", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (NvimApi.Tabpage(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func setCurrentTabpage(
    tabpage: NvimApi.Tabpage,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(tabpage.handle)),
      ]
      let response = self.session.rpc(method: "nvim_set_current_tabpage", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func subscribe(
    event: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(event),
      ]
      let response = self.session.rpc(method: "nvim_subscribe", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func unsubscribe(
    event: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .string(event),
      ]
      let response = self.session.rpc(method: "nvim_unsubscribe", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func getColorByName(
    name: String
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .string(name),
      ]
      let response = self.session.rpc(method: "nvim_get_color_by_name", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getColorMap(
  ) -> Single<Dictionary<String, NvimApi.Value>> {
  
    return Single<Dictionary<String, NvimApi.Value>>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_color_map", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getMode(
  ) -> Single<Dictionary<String, NvimApi.Value>> {
  
    return Single<Dictionary<String, NvimApi.Value>>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_mode", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (msgPackDictToSwift(value.dictionaryValue)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getKeymap(
    mode: String
  ) -> Single<[Dictionary<String, NvimApi.Value>]> {
  
    return Single<[Dictionary<String, NvimApi.Value>]>.create { single in
      let params: [NvimApi.Value] = [
          .string(mode),
      ]
      let response = self.session.rpc(method: "nvim_get_keymap", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (msgPackArrayDictToSwift(value.arrayValue)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func getApiInfo(
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          
      ]
      let response = self.session.rpc(method: "nvim_get_api_info", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func callAtomic(
    calls: NvimApi.Value
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          calls,
      ]
      let response = self.session.rpc(method: "nvim_call_atomic", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winGetBuf(
    window: NvimApi.Window
  ) -> Single<NvimApi.Buffer> {
  
    return Single<NvimApi.Buffer>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_buf", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (NvimApi.Buffer(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winGetCursor(
    window: NvimApi.Window
  ) -> Single<[Int]> {
  
    return Single<[Int]>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_cursor", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winSetCursor(
    window: NvimApi.Window,
    pos: [Int],
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .array(pos.map { .int(Int64($0)) }),
      ]
      let response = self.session.rpc(method: "nvim_win_set_cursor", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func winGetHeight(
    window: NvimApi.Window
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_height", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winSetHeight(
    window: NvimApi.Window,
    height: Int,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .int(Int64(height)),
      ]
      let response = self.session.rpc(method: "nvim_win_set_height", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func winGetWidth(
    window: NvimApi.Window
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_width", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winSetWidth(
    window: NvimApi.Window,
    width: Int,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .int(Int64(width)),
      ]
      let response = self.session.rpc(method: "nvim_win_set_width", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func winGetVar(
    window: NvimApi.Window,
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_win_get_var", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winSetVar(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_win_set_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func winDelVar(
    window: NvimApi.Window,
    name: String,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_win_del_var", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func winGetOption(
    window: NvimApi.Window,
    name: String
  ) -> Single<NvimApi.Value> {
  
    return Single<NvimApi.Value>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .string(name),
      ]
      let response = self.session.rpc(method: "nvim_win_get_option", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (Optional(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winSetOption(
    window: NvimApi.Window,
    name: String,
    value: NvimApi.Value,
    expectsReturnValue: Bool = true
  ) -> Single<Void> {
  
    return Single<Void>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
        .string(name),
        value,
      ]
      let response = self.session.rpc(method: "nvim_win_set_option", params: params, expectsReturnValue: expectsReturnValue)
      let disposable = Disposables.create()
      
      if let error = response.error {
        single(.error(error))
        return disposable
      }
      
      single(.success(()))
      return disposable
    }
  }

  public func winGetPosition(
    window: NvimApi.Window
  ) -> Single<[Int]> {
  
    return Single<[Int]>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_position", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.arrayValue?.flatMap({ v in (v.integerValue == nil ? nil : Int(v.integerValue!)) })) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winGetTabpage(
    window: NvimApi.Window
  ) -> Single<NvimApi.Tabpage> {
  
    return Single<NvimApi.Tabpage>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_tabpage", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (NvimApi.Tabpage(value)) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winGetNumber(
    window: NvimApi.Window
  ) -> Single<Int> {
  
    return Single<Int>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_get_number", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = ((value.integerValue == nil ? nil : Int(value.integerValue!))) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

  public func winIsValid(
    window: NvimApi.Window
  ) -> Single<Bool> {
  
    return Single<Bool>.create { single in
      let params: [NvimApi.Value] = [
          .int(Int64(window.handle)),
      ]
      let response = self.session.rpc(method: "nvim_win_is_valid", params: params, expectsReturnValue: true)
      let disposable = Disposables.create()
      
      guard let value = response.value else {
        single(.error(response.error!))
        return disposable
      }
      
      guard let result = (value.boolValue) else {
        single(.error(response.error!))
        return disposable
      }
      
      single(.success(result))
      return disposable
    }
  }

}

