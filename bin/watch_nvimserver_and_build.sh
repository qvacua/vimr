#!/bin/bash
set -Eeuo pipefail

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
    find NvimServer/Sources NvimServerTypes | grep -E '(\.h$|\.c$)' | entr -c ./bin/build_nvimserver_for_local_dev.sh
  popd >/dev/null
}

main