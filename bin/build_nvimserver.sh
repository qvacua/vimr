#!/bin/bash
set -Eeuo pipefail

# This script prepares Neovim binary and the runtime files for building VimR.
# For most cases, you can just download the pre-built universal Neovim releases by running
# `clean=true for_dev=false ./bin/neovim/bin/download_neovim_releases.sh`
# If you want to build Neovim locally, use `for_dev=true`, then, the Neovim binary will be
# built for the current architecture only and using the simple `make` command.

declare -r -x clean=${clean:-true}
declare -r -x for_dev=${for_dev:-false}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  local -r resources_folder="./NvimView/Sources/NvimView/Resources"

  # Only clean/download if explicitly requested or if resources are missing
  if [[ "${clean}" == true ]] || [[ ! -f "${resources_folder}/NvimServer" ]]; then
    echo "### Preparing Neovim resources (clean=${clean})..."
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

      ./bin/neovim/bin/build_neovim_for_dev.sh

      pushd ./Neovim/build >/dev/null
      local arch
      arch="$(uname -m)"
      readonly arch
      tar -xf "nvim-macos-${arch}.tar.gz"
      popd >/dev/null

      cp "./Neovim/build/nvim-macos-${arch}/bin/nvim" "${resources_folder}/NvimServer"
      cp -r "./Neovim/build/nvim-macos-${arch}/share/nvim/runtime" "${resources_folder}"

    else

      local neovim_release
      neovim_release=$(jq -r ".neovimRelease" ./bin/neovim/resources/buildInfo.json)
      readonly neovim_release

      pushd ./Neovim >/dev/null
      mkdir -p build
      pushd ./build >/dev/null
      curl -LO "https://github.com/qvacua/vimr/releases/download/${neovim_release}/nvim-macos-universal.tar.bz"
      tar -xf nvim-macos-universal.tar.bz
      popd >/dev/null
      popd >/dev/null

      cp ./Neovim/build/nvim-macos-universal/bin/nvim "${resources_folder}/NvimServer"
      cp -r ./Neovim/build/nvim-macos-universal/share/nvim/runtime "${resources_folder}"

    fi
  else
    echo "### Neovim resources found. Skipping download/build."
  fi

  # Copy VimR specific vim file to runtime/plugin folder
  # Only copy if content changed to avoid updating timestamp and triggering Xcode rebuilds
  if ! cmp -s "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin/com.qvacua.NvimView.vim"; then
    cp "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin"
  fi

  popd >/dev/null
}

main
