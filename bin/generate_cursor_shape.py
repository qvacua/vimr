#!/usr/local/bin/python3

import io
import os
import re

from string import Template

# Assume that we're in $REPO_ROOT/NvimView

NVIM_CURSOR_SHAPE_ENUM_FILE = "./neovim/src/nvim/cursor_shape.h"
SWIFT_TEMPLATE_FILE = "../resources/cursor_shape.template.swift"

SHAPE_NAMES = {
    "SHAPE_IDX_N":      (0, "normal"),
    "SHAPE_IDX_V":      (1, "visual"),
    "SHAPE_IDX_I":      (2, "insert"),
    "SHAPE_IDX_R":      (3, "replace"),
    "SHAPE_IDX_C":      (4, "cmdlineNormal"),
    "SHAPE_IDX_CI":     (5, "cmdlineInsert"),
    "SHAPE_IDX_CR":     (6, "cmdlineReplace"),
    "SHAPE_IDX_O":      (7, "operatorPending"),
    "SHAPE_IDX_VE":     (8, "visualExclusive"),
    "SHAPE_IDX_CLINE":  (9, "onCmdline"),
    "SHAPE_IDX_STATUS": (10, "onStatusLine"),
    "SHAPE_IDX_SDRAG":  (11, "draggingStatusLine"),
    "SHAPE_IDX_VSEP":   (12, "onVerticalSepLine"),
    "SHAPE_IDX_VDRAG":  (13, "draggingVerticalSepLine"),
    "SHAPE_IDX_MORE":   (14, "more"),
    "SHAPE_IDX_MOREL":  (15, "moreLastLine"),
    "SHAPE_IDX_SM":     (16, "showingMatchingParen"),
    "SHAPE_IDX_TERM":   (17, "termFocus"),
    "SHAPE_IDX_COUNT":  (18, "count"),
}


def are_shapes_same() -> bool:
    with io.open(NVIM_CURSOR_SHAPE_ENUM_FILE, "r") as cursor_shape_header:
        shape_regex = r'^\s*(SHAPE_IDX_[A-Z]+)\s*= ([0-9]+)'
        shape_lines = [re.match(shape_regex, line) for line in cursor_shape_header]
        nvim_shapes = [m.groups() for m in shape_lines if m]

        return set(nvim_shapes) == set([(k, str(v[0])) for (k, v) in SHAPE_NAMES.items()])


def swift_shapes() -> str:
    with io.open(SWIFT_TEMPLATE_FILE, "r") as template_file:
        template = Template(template_file.read())
        cases = "\n".join([f"  case {v[1]} = {v[0]}" for (k, v) in SHAPE_NAMES.items()])
        return template.substitute(
            cursor_shapes=cases,
            version=version
        )


if __name__ == "__main__":
    version = os.environ['version']
    assert are_shapes_same()

    print(swift_shapes())
