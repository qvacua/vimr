#!/usr/bin/env python3

import io
import os
import subprocess
from string import Template

import msgpack

from api_generator_common import (
    msgpack_to_swift,
    nvim_type_to_swift,
    parse_args,
    parse_error_cases,
    parse_error_types,
    parse_params,
    parse_version,
    snake_to_camel,
)

void_func_template = Template(
    """\
  func ${func_name}(${args}
    expectsReturnValue: Bool = false
  ) async -> Result<Void, NvimApi.Error> {

    let params: [NvimApi.Value] = [
        ${params}
    ]

    if expectsReturnValue, let error = await self.blockedError() { return .failure(error) }
    
    let reqResult = await self.sendRequest(method: "${nvim_func_name}", params: params)
    switch reqResult {
    case .success:
      return .success(())
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }
"""
)

get_mode_func_template = Template(
    """\
  func ${func_name}(${args}
  ) async -> Result<${result_type}, NvimApi.Error> {

    let params: [NvimApi.Value] = [
        ${params}
    ]
    
    let reqResult = await self.sendRequest(method: "${nvim_func_name}", params: params)
    switch reqResult {
    case let .success(value):
      guard let result =  (${return_value}) else {
        return .failure(Error.conversion(type: ${result_type}.self))
      }
      return .success(result)

    case let .failure(error):
      return .failure(error)
    }
  }
"""
)

func_template = Template(
    """\
  func ${func_name}(${args}
    errWhenBlocked: Bool = true
  ) async -> Result<${result_type}, NvimApi.Error> {

    let params: [NvimApi.Value] = [
        ${params}
    ]

    func transform(_ value: NvimApi.Value) throws(NvimApi.Error) -> ${result_type} {
      guard let result = (${return_value}) else {
        throw NvimApi.Error.conversion(type: ${result_type}.self)
      }

      return result
    }

    if errWhenBlocked, let error = await self.blockedError() { return .failure(error) }
    
    let reqResult = await self.sendRequest(method: "${nvim_func_name}", params: params)
    switch reqResult {
    case let .success(value):
      return Result { () throws(NvimApi.Error) -> ${result_type} in
        try transform(value)
      }
    case let .failure(error):
      return .failure(.other(cause: error))
    }
  }
"""
)

extension_template = Template(
    """\
// Auto generated for nvim version ${version}.
// See bin/generate_api_methods.py

import Foundation
import MessagePack

extension NvimApi {

  public enum Error: Swift.Error, Sendable {

    ${error_types}

    case exception(message: String)
    case validation(message: String)
    case blocked
    case conversion(type: Any.Type)
    case other(cause: Swift.Error)
    case other(description: String)
    case unknown

    init(_ value: NvimApi.Value?) {
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
      ${error_cases}
      default: self = .unknown
      }
    }
  }
}

public extension NvimApi {

$body
}

extension NvimApi.Buffer {

  public init?(_ value: NvimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == ${buffer_type} else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.int64Value else {
      return nil
    }

    self.handle = Int(handle)
  }
}

extension NvimApi.Window {

  public init?(_ value: NvimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == ${window_type} else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.int64Value else {
      return nil
    }

    self.handle = Int(handle)
  }
}

extension NvimApi.Tabpage {

  public init?(_ value: NvimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == ${tabpage_type} else {
      return nil
    }

    guard let handle = (try? unpack(data))?.value.int64Value else {
      return nil
    }

    self.handle = Int(handle)
  }
}
"""
)


def parse_function(f):
    args = parse_args(f["parameters"])
    template = void_func_template if f["return_type"] == "void" else func_template
    nvim_func_name = f["name"]
    template = get_mode_func_template if nvim_func_name == "nvim_get_mode" else template

    result = template.substitute(
        func_name=snake_to_camel(nvim_func_name),
        nvim_func_name=nvim_func_name,
        args=args,
        params=parse_params(f["parameters"]),
        result_type=nvim_type_to_swift(f["return_type"]),
        return_value=msgpack_to_swift("value", nvim_type_to_swift(f["return_type"])),
    )

    if "deprecated_since" in f:
        result = (
            '  @available(*, deprecated, message: "This method has been deprecated.")\n' + result
        )

    return result


if __name__ == "__main__":
    result_file_path = "./Sources/NvimApi/NvimApi.generated.swift"

    nvim_path = os.environ["NVIM_PATH"] if "NVIM_PATH" in os.environ else "nvim"

    nvim_output = subprocess.run([nvim_path, "--api-info"], stdout=subprocess.PIPE)
    api = msgpack.unpackb(nvim_output.stdout, raw=False)

    version = parse_version(api["version"])
    functions = api["functions"]
    body = "\n".join([parse_function(f) for f in functions])

    result = extension_template.substitute(
        body=body,
        version=version,
        error_types=parse_error_types(api["error_types"]),
        error_cases=parse_error_cases(api["error_types"]),
        buffer_type=api["types"]["Buffer"]["id"],
        window_type=api["types"]["Window"]["id"],
        tabpage_type=api["types"]["Tabpage"]["id"],
    )

    with io.open(result_file_path, "w") as api_methods_file:
        api_methods_file.write(result)
