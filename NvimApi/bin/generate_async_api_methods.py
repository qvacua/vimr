#!/usr/bin/env python3

import io
import os
import re
import subprocess
import textwrap
from string import Template

import msgpack

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

    let transform = { (_ value: NvimApi.Value) throws(NvimApi.Error) -> ${result_type} in
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


def snake_to_camel(snake_str):
    components = snake_str.split("_")
    return components[0] + "".join(x.title() for x in components[1:])


def nvim_type_to_swift(nvim_type):
    if nvim_type == "Boolean":
        return "Bool"

    if nvim_type == "Integer":
        return "Int"

    if nvim_type == "Float":
        return nvim_type

    if nvim_type == "void":
        return "Void"

    if nvim_type == "String":
        return "String"

    if nvim_type == "Array":
        return "NvimApi.Value"

    if nvim_type == "Dict":
        return "Dictionary<String, NvimApi.Value>"

    if nvim_type == "Buffer":
        return "NvimApi.Buffer"

    if nvim_type == "Window":
        return "NvimApi.Window"

    if nvim_type == "Tabpage":
        return "NvimApi.Tabpage"

    if nvim_type == "Object":
        return "NvimApi.Value"

    if nvim_type.startswith("ArrayOf("):
        match = re.match(r"ArrayOf\((.*?)(?:, \d+)*\)", nvim_type)
        return "[{}]".format(nvim_type_to_swift(match.group(1)))

    print(f"{nvim_type} not known; defaulting to MessagePackValue")
    return "NvimApi.Value"


def msgpack_to_swift(msgpack_value_name, type):
    if type == "Bool":
        return f"{msgpack_value_name}.boolValue"

    if type == "Int":
        return f"({msgpack_value_name}.int64Value == nil ? nil : Int({msgpack_value_name}.int64Value!))"

    if type == "Float":
        return f"{msgpack_value_name}.floatValue"

    if type == "Void":
        return f"()"

    if type == "String":
        return f"{msgpack_value_name}.stringValue"

    if type == "NvimApi.Value":
        return f"Optional({msgpack_value_name})"

    if type in "NvimApi.Buffer":
        return f"NvimApi.Buffer({msgpack_value_name})"

    if type in "NvimApi.Window":
        return f"NvimApi.Window({msgpack_value_name})"

    if type in "NvimApi.Tabpage":
        return f"NvimApi.Tabpage({msgpack_value_name})"

    if type.startswith("Dictionary<"):
        return f"msgPackDictToSwift({msgpack_value_name}.dictionaryValue)"

    if type.startswith("[Dictionary<"):
        return f"msgPackArrayDictToSwift({msgpack_value_name}.arrayValue)"

    if type.startswith("["):
        element_type = re.match(r"\[(.*)\]", type).group(1)
        return f'{msgpack_value_name}.arrayValue?.compactMap({{ v in {msgpack_to_swift("v", element_type)} }})'

    return "NvimApi.Value"


def swift_to_msgpack_value(name, type):
    if type == "Bool":
        return f".bool({name})"

    if type == "Int":
        return f".int(Int64({name}))"

    if type == "Float":
        return f".float({name})"

    if type == "Void":
        return f".nil()"

    if type == "String":
        return f".string({name})"

    if type == "Dictionary<String, NvimApi.Value>":
        return f".map({name}.mapToDict({{ (Value.string($0), $1) }}))"

    if type == "NvimApi.Value":
        return name

    if type in ["NvimApi.Buffer", "NvimApi.Window", "NvimApi.Tabpage"]:
        return f".int(Int64({name}.handle))"

    if type.startswith("["):
        match = re.match(r"\[(.*)\]", type)
        test = "$0"
        return f".array({name}.map {{ {swift_to_msgpack_value(test, match.group(1))} }})"


def parse_args(raw_params):
    types = [nvim_type_to_swift(p[0]) for p in raw_params]
    names = [p[1] for p in raw_params]
    params = dict(zip(names, types))

    result = "\n".join([n + ": " + t + "," for n, t in params.items()])
    if not result:
        return ""

    return "\n" + textwrap.indent(result, "    ")


def parse_params(raw_params):
    types = [nvim_type_to_swift(p[0]) for p in raw_params]
    names = [p[1] for p in raw_params]
    params = dict(zip(names, types))

    result = "\n".join([swift_to_msgpack_value(n, t) + "," for n, t in params.items()])
    return textwrap.indent(result, "        ").strip()


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


def parse_version(version):
    return ".".join([str(v) for v in [version["major"], version["minor"], version["patch"]]])


def parse_error_types(error_types):
    return textwrap.indent(
        "\n".join(
            [
                f'public static let {t.lower()}RawValue = UInt64({v["id"]})'
                for t, v in error_types.items()
            ]
        ),
        "    ",
    ).lstrip()


def parse_error_cases(error_types):
    return textwrap.indent(
        "\n".join(
            [
                f"case Error.{t.lower()}RawValue: self = .{t.lower()}(message: message)"
                for t, v in error_types.items()
            ]
        ),
        "    ",
    ).lstrip()


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
