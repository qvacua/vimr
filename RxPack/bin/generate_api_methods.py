#!/usr/bin/env python3

import subprocess

import msgpack
from string import Template
import re
import textwrap
import os
import io


void_func_template = Template('''\
  public func ${func_name}(${args}
    expectsReturnValue: Bool = false
  ) -> Completable {

    let params: [RxNeovimApi.Value] = [
        ${params}
    ]

    if expectsReturnValue {
      return self
        .checkBlocked(
          self.sendRequest(method: "${nvim_func_name}", params: params)
        )
        .asCompletable()
    }

    return self
      .sendRequest(method: "${nvim_func_name}", params: params)
      .asCompletable()
  }
''')

get_mode_func_template = Template('''\
  public func ${func_name}(${args}
  ) -> Single<${result_type}> {

    let params: [RxNeovimApi.Value] = [
        ${params}
    ]
    return self
      .sendRequest(method: "${nvim_func_name}", params: params)
      .map { value in
        guard let result = (${return_value}) else {
          throw RxNeovimApi.Error.conversion(type: ${result_type}.self)
        }

        return result
      }
  }
''')

func_template = Template('''\
  public func ${func_name}(${args}
    errWhenBlocked: Bool = true
  ) -> Single<${result_type}> {

    let params: [RxNeovimApi.Value] = [
        ${params}
    ]

    let transform = { (_ value: Value) throws -> ${result_type} in
      guard let result = (${return_value}) else {
        throw RxNeovimApi.Error.conversion(type: ${result_type}.self)
      }

      return result
    }

    if errWhenBlocked {
      return self
        .checkBlocked(
          self.sendRequest(method: "${nvim_func_name}", params: params)
        )
        .map(transform)
    }

    return self
      .sendRequest(method: "${nvim_func_name}", params: params)
      .map(transform)
  }
''')

extension_template = Template('''\
// Auto generated for nvim version ${version}.
// See bin/generate_api_methods.py

import Foundation
import MessagePack
import RxSwift

extension RxNeovimApi {

  public enum Error: Swift.Error {

    ${error_types}

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
      ${error_cases}
      default: self = .unknown
      }
    }
  }
}

extension RxNeovimApi {

$body
}

extension RxNeovimApi.Buffer {

  public init?(_ value: RxNeovimApi.Value) {
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

extension RxNeovimApi.Window {

  public init?(_ value: RxNeovimApi.Value) {
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

extension RxNeovimApi.Tabpage {

  public init?(_ value: RxNeovimApi.Value) {
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
''')


def snake_to_camel(snake_str):
    components = snake_str.split('_')
    return components[0] + "".join(x.title() for x in components[1:])


def nvim_type_to_swift(nvim_type):
    if nvim_type == 'Boolean':
        return 'Bool'

    if nvim_type == 'Integer':
        return 'Int'

    if nvim_type == 'Float':
        return nvim_type

    if nvim_type == 'void':
        return 'Void'

    if nvim_type == 'String':
        return 'String'

    if nvim_type == 'Array':
        return 'RxNeovimApi.Value'

    if nvim_type == 'Dictionary':
        return 'Dictionary<String, RxNeovimApi.Value>'

    if nvim_type == 'Buffer':
        return 'RxNeovimApi.Buffer'

    if nvim_type == 'Window':
        return 'RxNeovimApi.Window'

    if nvim_type == 'Tabpage':
        return 'RxNeovimApi.Tabpage'

    if nvim_type == 'Object':
        return 'RxNeovimApi.Value'

    if nvim_type.startswith('ArrayOf('):
        match = re.match(r'ArrayOf\((.*?)(?:, \d+)*\)', nvim_type)
        return '[{}]'.format(nvim_type_to_swift(match.group(1)))

    return 'RxNeovimApi.Value'


def msgpack_to_swift(msgpack_value_name, type):
    if type == 'Bool':
        return f'{msgpack_value_name}.boolValue'

    if type == 'Int':
        return f'({msgpack_value_name}.int64Value == nil ? nil : Int({msgpack_value_name}.int64Value!))'

    if type == 'Float':
        return f'{msgpack_value_name}.floatValue'

    if type == 'Void':
        return f'()'

    if type == 'String':
        return f'{msgpack_value_name}.stringValue'

    if type == 'RxNeovimApi.Value':
        return f'Optional({msgpack_value_name})'

    if type in 'RxNeovimApi.Buffer':
        return f'RxNeovimApi.Buffer({msgpack_value_name})'

    if type in 'RxNeovimApi.Window':
        return f'RxNeovimApi.Window({msgpack_value_name})'

    if type in 'RxNeovimApi.Tabpage':
        return f'RxNeovimApi.Tabpage({msgpack_value_name})'

    if type.startswith('Dictionary<'):
        return f'msgPackDictToSwift({msgpack_value_name}.dictionaryValue)'

    if type.startswith('[Dictionary<'):
        return f'msgPackArrayDictToSwift({msgpack_value_name}.arrayValue)'

    if type.startswith('['):
        element_type = re.match(r'\[(.*)\]', type).group(1)
        return f'{msgpack_value_name}.arrayValue?.compactMap({{ v in {msgpack_to_swift("v", element_type)} }})'

    return 'RxNeovimApi.Value'


def swift_to_msgpack_value(name, type):
    if type == 'Bool':
        return f'.bool({name})'

    if type == 'Int':
        return f'.int(Int64({name}))'

    if type == 'Float':
        return f'.float({name})'

    if type == 'Void':
        return f'.nil()'

    if type == 'String':
        return f'.string({name})'

    if type == 'Dictionary<String, RxNeovimApi.Value>':
        return f'.map({name}.mapToDict({{ (Value.string($0), $1) }}))'

    if type == 'RxNeovimApi.Value':
        return name

    if type in ['RxNeovimApi.Buffer', 'RxNeovimApi.Window', 'RxNeovimApi.Tabpage']:
        return f'.int(Int64({name}.handle))'

    if type.startswith('['):
        match = re.match(r'\[(.*)\]', type)
        test = '$0'
        return f'.array({name}.map {{ {swift_to_msgpack_value(test, match.group(1))} }})'


def parse_args(raw_params):
    types = [nvim_type_to_swift(p[0]) for p in raw_params]
    names = [p[1] for p in raw_params]
    params = dict(zip(names, types))

    result = '\n'.join([n + ': ' + t + ',' for n, t in params.items()])
    if not result:
        return ''

    return '\n' + textwrap.indent(result, '    ')


def parse_params(raw_params):
    types = [nvim_type_to_swift(p[0]) for p in raw_params]
    names = [p[1] for p in raw_params]
    params = dict(zip(names, types))

    result = '\n'.join([swift_to_msgpack_value(n, t) + ',' for n, t in params.items()])
    return textwrap.indent(result, '        ').strip()


def parse_function(f):
    args = parse_args(f['parameters'])
    template = void_func_template if f['return_type'] == 'void' else func_template
    nvim_func_name = f['name']
    template = get_mode_func_template if nvim_func_name == 'nvim_get_mode' else template

    result = template.substitute(
        func_name=snake_to_camel(nvim_func_name),
        nvim_func_name=nvim_func_name,
        args=args,
        params=parse_params(f['parameters']),
        result_type=nvim_type_to_swift(f['return_type']),
        return_value=msgpack_to_swift('value', nvim_type_to_swift(f['return_type']))
    )

    if "deprecated_since" in f:
        result = '  @available(*, deprecated, message: "This method has been deprecated.")\n' + result

    return result


def parse_version(version):
    return '.'.join([str(v) for v in [version['major'], version['minor'], version['patch']]])


def parse_error_types(error_types):
    return textwrap.indent(
        '\n'.join(
            [f'public static let {t.lower()}RawValue = UInt64({v["id"]})' for t, v in error_types.items()]
        ),
        '    '
    ).lstrip()


def parse_error_cases(error_types):
    return textwrap.indent(
        '\n'.join(
            [f'case Error.{t.lower()}RawValue: self = .{t.lower()}(message: message)' for t, v in error_types.items()]
        ),
        '    '
    ).lstrip()


if __name__ == '__main__':
    result_file_path = './Sources/RxNeovim/RxNeovimApi.generated.swift'

    nvim_path = os.environ['NVIM_PATH'] if 'NVIM_PATH' in os.environ else 'nvim'

    nvim_output = subprocess.run([nvim_path, '--api-info'], stdout=subprocess.PIPE)
    api = msgpack.unpackb(nvim_output.stdout, raw=False)

    version = parse_version(api['version'])
    functions = api['functions']
    body = '\n'.join([parse_function(f) for f in functions])

    result = extension_template.substitute(
        body=body,
        version=version,
        error_types=parse_error_types(api['error_types']),
        error_cases=parse_error_cases(api['error_types']),
        buffer_type=api['types']['Buffer']['id'],
        window_type=api['types']['Window']['id'],
        tabpage_type=api['types']['Tabpage']['id']
    )

    with io.open(result_file_path, 'w') as api_methods_file:
        api_methods_file.write(result)
