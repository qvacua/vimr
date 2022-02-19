#!/bin/bash
set -Eeuo pipefail

readonly clean_initial_build=${clean_inital_build:-false}

clean_build() {
  local -r -x clean=true
  local -r -x build_libnvim=true
  ./bin/build_nvimserver_for_local_dev.sh
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
    if [[ "${clean_initial_build}" == true ]]; then
      clean_build
    fi

    find NvimServer/NvimServer/Sources NvimServer/NvimServerTypes | grep -E '(\.h$|\.c$)' | entr -c ./bin/build_nvimserver_for_local_dev.sh
  popd >/dev/null
}

main
