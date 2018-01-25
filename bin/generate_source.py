#!/usr/bin/env python3

import os
import io
import re
from string import Template


def convert(line):
    result = re.match(r'^EVENT_(.*) = (.*)', line.replace(',', ''))
    return result.group(1), result.group(2)


def swift_auto_cmds():
    with io.open('./neovim/build/include/auevents_enum.generated.h', 'r') as auto_cmds_file:
        raw_auto_cmds = [line.strip() for line in auto_cmds_file.readlines() if re.match(r'^EVENT_', line.strip())]

    auto_cmds = [convert(line) for line in raw_auto_cmds]
    auto_cmds_template = Template(
'''// Auto generated for nvim version 0.2.2.
// See bin/generate_source.py

enum NvimAutoCommandEvent: Int {
${event_cases}
}
'''
    )

    return auto_cmds_template.substitute(
        event_cases='\n'.join(
            ['  case {} = {}'.format(event[0].lower(), event[1]) for event in auto_cmds]
        ),
    )


if __name__ == '__main__':
    result_file_path = './NvimView/NvimAutoCommandEvent.generated.swift'

    if 'CONFIGURATION' in os.environ and os.environ['CONFIGURATION'] == 'Debug':
        if os.path.isfile(result_file_path):
            print("Files already there, exiting...")
            exit(0)

    with io.open(result_file_path, 'w') as auto_cmds_header_file:
        auto_cmds_header_file.write(swift_auto_cmds())
