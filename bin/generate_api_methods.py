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
    expectsReturnValue: Bool = true,
    checkBlocked: Bool = true
  ) -> Completable {
 
    let params: [NvimApi.Value] = [
        ${params}
    ]
    
    if expectsReturnValue && checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: expectsReturnValue)
        )
        .asCompletable()
    } 
    
    return self
      .rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: expectsReturnValue)
      .asCompletable()
  }
''')

get_mode_func_template = Template('''\
  public func ${func_name}(${args}
  ) -> Single<${result_type}> {
 
    let params: [NvimApi.Value] = [
        ${params}
    ]
    return self
      .rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: true)
      .map { value in
        guard let result = (${return_value}) else {
          throw NvimApi.Error.conversion(type: ${result_type}.self)
        }

        return result
      }
  }
''')

func_template = Template('''\
  public func ${func_name}(${args}
    checkBlocked: Bool = true
  ) -> Single<${result_type}> {
 
    let params: [NvimApi.Value] = [
        ${params}
    ]
    
    func transform(_ value: Value) throws -> ${result_type} {
      guard let result = (${return_value}) else {
        throw NvimApi.Error.conversion(type: ${result_type}.self)
      }

      return result
    }
    
    if checkBlocked {
      return self
        .checkBlocked(
          self.rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: true)
        )
        .map(transform)
    }
    
    return self
      .rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: true)
      .map(transform)
  }
''')

extension_template = Template('''\
// Auto generated for nvim version ${version}.
// See bin/generate_api_methods.py

import Foundation
import RxMsgpackRpc
import MessagePack
import RxSwift

extension NvimApi {

  public enum Error: Swift.Error {

    ${error_types}

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

  init?(_ value: NvimApi.Value) {
    guard let (type, data) = value.extendedValue else {
      return nil
    }

    guard type == ${buffer_type} else {
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

    guard type == ${window_type} else {
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

    guard type == ${tabpage_type} else {
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
        return 'NvimApi.Value'

    if nvim_type == 'Dictionary':
        return 'Dictionary<String, NvimApi.Value>'

    if nvim_type == 'Buffer':
        return 'NvimApi.Buffer'

    if nvim_type == 'Window':
        return 'NvimApi.Window'

    if nvim_type == 'Tabpage':
        return 'NvimApi.Tabpage'

    if nvim_type == 'Object':
        return 'NvimApi.Value'

    if nvim_type.startswith('ArrayOf('):
        match = re.match(r'ArrayOf\((.*?)(?:, \d+)*\)', nvim_type)
        return '[{}]'.format(nvim_type_to_swift(match.group(1)))

    return 'NvimApi.Value'


def msgpack_to_swift(msgpack_value_name, type):
    if type == 'Bool':
        return f'{msgpack_value_name}.boolValue'

    if type == 'Int':
        return f'({msgpack_value_name}.integerValue == nil ? nil : Int({msgpack_value_name}.integerValue!))'

    if type == 'Float':
        return f'{msgpack_value_name}.floatValue'

    if type == 'Void':
        return f'()'

    if type == 'String':
        return f'{msgpack_value_name}.stringValue'

    if type == 'NvimApi.Value':
        return f'Optional({msgpack_value_name})'

    if type in 'NvimApi.Buffer':
        return f'NvimApi.Buffer({msgpack_value_name})'

    if type in 'NvimApi.Window':
        return f'NvimApi.Window({msgpack_value_name})'

    if type in 'NvimApi.Tabpage':
        return f'NvimApi.Tabpage({msgpack_value_name})'

    if type.startswith('Dictionary<'):
        return f'msgPackDictToSwift({msgpack_value_name}.dictionaryValue)'

    if type.startswith('[Dictionary<'):
        return f'msgPackArrayDictToSwift({msgpack_value_name}.arrayValue)'

    if type.startswith('['):
        element_type = re.match(r'\[(.*)\]', type).group(1)
        return f'{msgpack_value_name}.arrayValue?.compactMap({{ v in {msgpack_to_swift("v", element_type)} }})'

    return 'NvimApi.Value'


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

    if type == 'Dictionary<String, NvimApi.Value>':
        return f'.map({name}.mapToDict({{ (Value.string($0), $1) }}))'

    if type == 'NvimApi.Value':
        return name

    if type in ['NvimApi.Buffer', 'NvimApi.Window', 'NvimApi.Tabpage']:
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
    template = get_mode_func_template if f['name'] == 'nvim_get_mode' else template
    result = template.substitute(
        func_name=snake_to_camel(f['name'][5:]),
        nvim_func_name=f['name'],
        args=args,
        params=parse_params(f['parameters']),
        result_type=nvim_type_to_swift(f['return_type']),
        return_value=msgpack_to_swift('value', nvim_type_to_swift(f['return_type']))
    )

    return result


def parse_version(version):
    return '.'.join([str(v) for v in [version['major'], version['minor'], version['patch']]])


def parse_error_types(error_types):
    return textwrap.indent(
        '\n'.join(
            [f'private static let {t.lower()}RawValue = UInt64({v["id"]})' for t, v in error_types.items()]
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
    result_file_path = './NvimMsgPack/NvimApiMethods.generated.swift'

    if 'CONFIGURATION' in os.environ and os.environ['CONFIGURATION'] == 'Debug':
        if os.path.isfile(result_file_path):
            print("Files already there and DEBUG, exiting...")
            exit(0)

    nvim_path = os.environ['NVIM_PATH'] if 'NVIM_PATH' in os.environ else 'nvim'

    nvim_output = subprocess.run([nvim_path, '--api-info'], stdout=subprocess.PIPE)
    api = msgpack.unpackb(nvim_output.stdout, encoding='utf-8')

    version = parse_version(api['version'])
    functions = [f for f in api['functions'] if 'deprecated_since' not in f]
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
