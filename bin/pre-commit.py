#!/usr/bin/env python3

import subprocess
from typing import List

RELEVANT_PATHS = [
    "Commons/Sources/Commons",
    "Ignore/Sources/Ignore",
    "NvimApi/Sources/NvimApi",
    "NvimView/Sources/NvimApi",
    "Tabs/Sources/Tabs",
    "VimR/VimR",
    "Workspace/Sources/Workspace",
]

def lint(changed_files: List[str]) -> None:
    for path in RELEVANT_PATHS:
        if any(file.startswith(path) for file in changed_files):
            subprocess.run(["swiftlint", path], check=True)


def format(changed_files: List[str]) -> None:
    for file in [f for f in changed_files if f.endswith(".swift")]:
        subprocess.run(["swiftformat", file], check=True)


if __name__ == "__main__":
    changed_files = subprocess.run(
        "git diff --cached --name-only --diff-filter=ACMR".split(" "),
        capture_output=True,
        text=True,
        check=True,
    ).stdout.splitlines()

    lint(changed_files)
    format(changed_files)
