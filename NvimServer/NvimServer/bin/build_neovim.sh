#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false"}
readonly NVIM_BUILD_TYPE=${NVIM_BUILD_TYPE:-"Release"}

build_neovim() {
  # slightly modified version of /Neovim/.github/scripts/build_universal_macos.sh
  local -r MACOSX_DEPLOYMENT_TARGET=$1

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/opt/homebrew/opt/gettext/bin:/usr/local/opt/gettext/bin:${PATH}"
  
  export MACOSX_DEPLOYMENT_TARGET
  export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
  cmake -S cmake.deps -B .deps -G Ninja \
    -D CMAKE_BUILD_TYPE=${NVIM_BUILD_TYPE} \
    -D CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
    -D CMAKE_OSX_ARCHITECTURES=arm64\;x86_64 \
    -D CMAKE_FIND_FRAMEWORK=NEVER
  cmake --build .deps
  cmake -B build -G Ninja \
    -D CMAKE_BUILD_TYPE=${NVIM_BUILD_TYPE} \
    -D CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
    -D CMAKE_OSX_ARCHITECTURES=arm64\;x86_64 \
    -D CMAKE_FIND_FRAMEWORK=NEVER
  cmake --build build
  cpack --config build/CPackConfig.cmake
}

main() {
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../../" >/dev/null
  
  ./NvimServer/bin/prepare_libintl.sh

  local deployment_target
  deployment_target=$(jq -r .deploymentTarget ./NvimServer/Resources/buildInfo.json)
  readonly deployment_target
  
  pushd ../Neovim >/dev/null
    echo "### Building neovim binary"
    if [[ "${clean}" == true ]]; then
      make distclean
    fi

    build_neovim "${deployment_target}"
  popd >/dev/null

  popd >/dev/null
}

main
