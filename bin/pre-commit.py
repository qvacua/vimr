#!/usr/bin/env python3

from typing import List

from shelly import sh, shout

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
            sh(["swiftlint", path])


def format(changed_files: List[str]) -> None:
    for file in [f for f in changed_files if f.endswith(".swift")]:
        sh(["swiftformat", file])
        sh(["git", "add", file])


if __name__ == "__main__":
    changed_files = shout("git diff --cached --name-only --diff-filter=ACMR").splitlines()

    lint(changed_files)
    format(changed_files)
