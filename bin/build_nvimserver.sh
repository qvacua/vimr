#!/bin/bash
set -Eeuo pipefail

declare -r -x clean=${clean:-false}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  resources_folder="./NvimView/Sources/NvimView/Resources"
  rm -rf "${resources_folder}/NvimServer"
  rm -rf "${resources_folder}/runtime"

  # Build NvimServer and copy
  ./bin/neovim/bin/build_neovim.sh
  pushd ./Neovim/build >/dev/null
    tar -xf nvim-macos.tar.gz
  popd >/dev/null

  cp ./Neovim/build/nvim-macos/bin/nvim "${resources_folder}/NvimServer"

  # Create and copy runtime folder
  cp -r ./Neovim/build/nvim-macos/share/nvim/runtime "${resources_folder}"

  # Copy VimR specific vim file to runtime/plugin folder
  cp "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin"

  popd >/dev/null
}

main
