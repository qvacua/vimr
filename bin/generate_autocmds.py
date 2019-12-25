#!/usr/bin/env python3

import os
import io
import re
from string import Template

NVIM_AUEVENTS_ENUM_FILE = "./neovim/build/include/auevents_enum.generated.h"

SWIFT_TEMPLATE_FILE = "../resources/autocmds.template.swift"
SWIFT_AUTOCMDS_FILE = './NvimView/NvimAutoCommandEvent.generated.swift'


def convert(line: str) -> (str, str):
    result = re.match(r'^EVENT_(.*) = (.*)', line.replace(',', ''))
    return result.group(1), result.group(2)


def swift_autocmds(version: str, template_string: str) -> str:
    with io.open(NVIM_AUEVENTS_ENUM_FILE, "r") as auto_cmds_file:
        raw_auto_cmds = [line.strip() for line in auto_cmds_file.readlines() if re.match(r'^EVENT_', line.strip())]

    autocmds = [convert(line) for line in raw_auto_cmds]
    template = Template(template_string)

    return template.substitute(
        event_cases="\n".join(
            [f"  case {event[0].lower()} = {event[1]}" for event in autocmds]
        ),
        version=version
    )


if __name__ == '__main__':
    result_file_path = SWIFT_AUTOCMDS_FILE
    version = os.environ['version']
    with io.open(SWIFT_TEMPLATE_FILE, "r") as template, \
            io.open(result_file_path, 'w') as header_file:
        header_file.write(swift_autocmds(version, template.read()))
