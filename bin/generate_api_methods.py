#!/usr/bin/env python3

import subprocess
import msgpack
from string import Template
import re
import textwrap
import os


void_func_template = Template('''\
  public func ${func_name}(${args}
    expectsReturnValue: Bool = true
  ) -> Nvim.Response<Void> {
  
    let params: [Nvim.Value] = [
        ${params}
    ]
    let response = self.rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: expectsReturnValue)
    
    if let error = response.error {
      return .failure(error)
    }
    
    return .success(())
  }
''')

func_template = Template('''\
  public func ${func_name}(${args}
    expectsReturnValue: Bool = true
  ) -> Nvim.Response<${result_type}> {
  
    let params: [Nvim.Value] = [
        ${params}
    ]
    let response = self.rpc(method: "${nvim_func_name}", params: params, expectsReturnValue: expectsReturnValue)
    
    guard let value = response.value else {
      return .failure(response.error!)
    }
    
    guard let result = (${return_value}) else {
      return .failure(Nvim.Error("Error converting result to \\(${result_type}.self)"))
    }
    
    return .success(result)
  }
''')

extension_template = Template('''// Auto generated for nvim version ${version}.
// See bin/generate_api_methods.py

import MessagePack

extension Nvim {

$body
}

extension Nvim.Buffer {

  init?(_ value: Nvim.Value) {
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

extension Nvim.Window {

  init?(_ value: Nvim.Value) {
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

extension Nvim.Tabpage {

  init?(_ value: Nvim.Value) {
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
}''')


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
        return 'Nvim.Value'

    if nvim_type == 'Dictionary':
        return 'Nvim.Value'

    if nvim_type == 'Buffer':
        return 'Nvim.Buffer'

    if nvim_type == 'Window':
        return 'Nvim.Window'

    if nvim_type == 'Tabpage':
        return 'Nvim.Tabpage'

    if nvim_type == 'Object':
        return 'Nvim.Value'

    if nvim_type.startswith('ArrayOf('):
        match = re.match(r'ArrayOf\((.*?)(?:, \d+)*\)', nvim_type)
        return '[{}]'.format(nvim_type_to_swift(match.group(1)))

    return 'Nvim.Value'


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

    if type == 'Nvim.Value':
        return f'Optional({msgpack_value_name})'

    if type in 'Nvim.Buffer':
        return f'Nvim.Buffer({msgpack_value_name})'

    if type in 'Nvim.Window':
        return f'Nvim.Window({msgpack_value_name})'

    if type in 'Nvim.Tabpage':
        return f'Nvim.Tabpage({msgpack_value_name})'

    if type.startswith('['):
        element_type = re.match(r'\[(.*)\]', type).group(1)
        return f'{msgpack_value_name}.arrayValue?.flatMap({{ v in {msgpack_to_swift("v", element_type)} }})'

    return 'Nvim.Value'


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

    if type == 'Nvim.Value':
        return name

    if type in ['Nvim.Buffer', 'Nvim.Window', 'Nvim.Tabpage']:
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


if __name__ == '__main__':
    nvim_path = os.environ['NVIM_PATH'] if 'NVIM_PATH' in os.environ else 'nvim'

    nvim_output = subprocess.run([nvim_path, '--api-info'], stdout=subprocess.PIPE)
    api = msgpack.unpackb(nvim_output.stdout, encoding='utf-8')

    version = parse_version(api['version'])
    functions = [f for f in api['functions'] if 'deprecated_since' not in f]
    body = '\n'.join([parse_function(f) for f in functions])

    print(extension_template.substitute(
        body=body,
        version=version,
        buffer_type=api['types']['Buffer']['id'],
        window_type=api['types']['Window']['id'],
        tabpage_type=api['types']['Tabpage']['id']
    ))
