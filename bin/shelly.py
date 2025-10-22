import shlex
import subprocess
from typing import List


def sh(cmd: str | List[str], check: bool = True) -> int:
    """Execute a shell command and return its stdout output.

    WARNING: This function does NOT support shell features like wildcards.
    """
    args = cmd
    if isinstance(cmd, str):
        args = shlex.split(cmd)
    return subprocess.run(args, check=check).returncode


def shout(cmd: str | List[str], check: bool = True) -> str:
    """Execute a shell command and return its stdout output.

    WARNING: This function does NOT support shell features like wildcards.
    """
    args = cmd
    if isinstance(cmd, str):
        args = shlex.split(cmd)
    return subprocess.run(args, check=check, text=True, capture_output=True).stdout
