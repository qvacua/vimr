#!/bin/bash
set -Eeuo pipefail

declare -x target; target="$(uname -m)"; readonly target
declare -r -x download_gettext=${download_gettext:-false}
declare -r -x clean=${clean:-false}
declare -r -x build_libnvim=${build_libnvim:-true}
declare -r -x build_dir=${build_dir:-"./build"}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  pushd "./NvimServer"
    ./NvimServer/bin/build_nvimserver.sh
    cp ./build/Build/Products/Release/NvimServer ../NvimView/Sources/NvimView
    cp -r ./runtime ../NvimView/Sources/NvimView
    cp ../NvimView/Sources/NvimView/com.qvacua.NvimView.vim ../NvimView/Sources/NvimView/runtime/plugin

  popd >/dev/null

  popd >/dev/null
}

main
