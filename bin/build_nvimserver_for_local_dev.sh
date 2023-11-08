#!/bin/bash
set -Eeuo pipefail

declare -r -x clean=${clean:-false}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

    pushd "./NvimServer"
      ./NvimServer/bin/build_neovim.sh
    popd

    pushd ./Neovim/build
      tar -xf nvim-macos.tar.gz
      cp ./nvim-macos/bin/nvim ../../NvimView/Sources/NvimView/Resources/NvimServer
      cp -r ./nvim-macos/share/nvim/runtime ../../NvimView/Sources/NvimView/Resources
    popd

    cp ./NvimView/Sources/NvimView/Resources/com.qvacua.NvimView.vim ./NvimView/Sources/NvimView/Resources/runtime/plugin

  popd >/dev/null
}

main
