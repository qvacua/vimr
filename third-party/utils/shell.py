import subprocess
import sys
from pathlib import Path


class ShellExecutionException(Exception):
    pass


def shell(command: str, cwd: Path):
    proc = subprocess.Popen(
        command, cwd=cwd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    for line in iter(lambda: proc.stdout.read(1), b""):
        sys.stdout.write(line.decode("utf-8"))

    if proc.poll() != 0:
        raise ShellExecutionException(command)