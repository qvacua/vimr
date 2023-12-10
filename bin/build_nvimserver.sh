#!/bin/bash
set -Eeuo pipefail

declare -r -x clean=${clean:-false}
declare -r -x for_dev=${for_dev:-false}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  resources_folder="./NvimView/Sources/NvimView/Resources"
  rm -rf "${resources_folder}/NvimServer"
  rm -rf "${resources_folder}/runtime"

  if [[ "${clean}" == true ]]; then
    pushd ./Neovim >/dev/null
      rm -rf .deps
      rm -rf build
      make distclean
    popd >/dev/null
  fi

  if [[ "${for_dev}" == true ]]; then
    pushd ./Neovim >/dev/null
      make CMAKE_BUILD_TYPE=Release
    popd >/dev/null

    cp ./Neovim/build/bin/nvim "${resources_folder}/NvimServer"
    cp -r ./Neovim/build/runtime "${resources_folder}"
  else
    ./bin/neovim/bin/build_neovim.sh
    pushd ./Neovim/build >/dev/null
      tar -xf nvim-macos.tar.gz
    popd >/dev/null
    cp ./Neovim/build/nvim-macos/bin/nvim "${resources_folder}/NvimServer"
    cp -r ./Neovim/build/nvim-macos/share/nvim/runtime "${resources_folder}"
  fi

  # Copy VimR specific vim file to runtime/plugin folder
  cp "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin"

  popd >/dev/null
}

main
