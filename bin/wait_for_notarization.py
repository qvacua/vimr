#!/usr/local/bin/python3

from waiting import wait, TimeoutExpired
import os
import subprocess


def check_status(request_uuid: str) -> bool:
    proc = subprocess.run(
        f"xcrun altool --notarization-info {request_uuid} -u hataewon@gmail.com -p @keychain:dev-notar".split(),
        capture_output=True
    )
    lines = proc.stdout.decode("utf-8").split("\n")

    success = [line for line in lines if "Status: success" in line]
    inprog = [line for line in lines if "Status: in progress" in line]
    invalid = [line for line in lines if "Status: invalid" in line]

    if invalid:
        print("### ERROR: notarization unsuccessful!")
        exit(1)

    if success:
        print("### Notarization successful")
        return True

    if inprog:
        print("### Notarization in progress")
        return False

    print("### Notarization status unclear, probably in progress")
    return False


if __name__ == "__main__":
    request_uuid = os.environ["request_uuid"]
    print(f"### Waiting for request {request_uuid}")

    try:
        wait(lambda: check_status(request_uuid), timeout_seconds=60*60, sleep_seconds=30)
    except TimeoutExpired:
        print("### ERROR: Timeout of 1h!")
        exit(1)
    except Exception as err:
        print(f"### ERROR: err")
        exit(1)
