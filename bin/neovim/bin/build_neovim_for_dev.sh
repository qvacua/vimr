#!/bin/bash
set -Eeuo pipefail

# This script builds Neovim with gettext for host's architecture, *no* universal build
# Produces /Neovim/build/neovim-macos-$arch.tar.gz

readonly clean=${clean:?"true or false"}
readonly NVIM_BUILD_TYPE=${NVIM_BUILD_TYPE:-"Release"}

build_neovim() {
  # slightly modified version of Neovim's Github workflow for release
  local -r -x MACOSX_DEPLOYMENT_TARGET=$1
  local -x SDKROOT; SDKROOT=$(xcrun --sdk macosx --show-sdk-path); readonly SDKROOT

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/opt/homebrew/opt/gettext/bin:/usr/local/opt/gettext/bin:${PATH}"

  make CMAKE_BUILD_TYPE="${NVIM_BUILD_TYPE}"
  cpack --config build/CPackConfig.cmake
}

main() {
  # This script is located in /bin/neovim/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../../../" >/dev/null

  local deployment_target
  deployment_target=$(jq -r .deploymentTarget ./bin/neovim/resources/buildInfo.json)
  readonly deployment_target

  pushd ./Neovim >/dev/null
    echo "### Building neovim binary"
    if [[ "${clean}" == true ]]; then
      make distclean
    fi

    build_neovim "${deployment_target}"
  popd >/dev/null

  popd >/dev/null
}

main

