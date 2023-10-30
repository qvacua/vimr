#!/bin/bash
set -Eeuo pipefail

declare -r -x clean=${clean:?"if true, will clean libnvim and nvimserver"}
readonly build_libnvim=${build_libnvim:?"true or false"}
readonly build_dir=${build_dir:-"./.build"}

main() {
  echo "### Building NvimServer"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
    if [[ "${clean}" == true ]]; then
      rm -rf "${build_dir}"
    fi

    if [[ "${build_libnvim}" == true ]]; then
      ./NvimServer/bin/build_libnvim.sh
    fi

    swift build --arch arm64 --arch x86_64 -c release --product NvimServer

  popd >/dev/null
  echo "### Built NvimServer"
}

main
