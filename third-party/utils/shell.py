import subprocess
import sys
from pathlib import Path


class ShellExecutionException(Exception):
    pass


def shell(command: str, cwd: Path):
    with subprocess.Popen(
        command, cwd=cwd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    ) as proc:
        while proc.stdout.readable():
            if line := proc.stdout.readline():
                sys.stdout.write(line.decode("utf-8"))
            else:
                break

        if proc.wait() != 0:
            raise ShellExecutionException(command)
