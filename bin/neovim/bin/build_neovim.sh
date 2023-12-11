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

  # See https://matrix.to/#/!cylwlNXSwagQmZSkzs:matrix.org/$WxndooGmUtD0a4IqjnALvZ_okHw3Gb0TZJIrc77T-SM?via=matrix.org&via=gitter.im&via=envs.net for libintl

  cmake -B build -G Ninja \
    -D CMAKE_BUILD_TYPE=${NVIM_BUILD_TYPE} \
    -D CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
    -D CMAKE_OSX_ARCHITECTURES=arm64\;x86_64 \
    -D CMAKE_FIND_FRAMEWORK=NEVER \
    -D LIBINTL_INCLUDE_DIR=../bin/neovim/third-party/gettext/include \
    -D LIBINTL_LIBRARY=../bin/neovim/third-party/gettext/lib/libintl.a
  cmake --build build

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
