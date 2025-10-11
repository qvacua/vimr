#!/usr/bin/env python3

import re
import textwrap


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
        return f".map({name}.mapToDict({{ (NvimApi.Value.string($0), $1) }}))"

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
