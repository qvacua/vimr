#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false"}

build_libnvim() {
  local -r deployment_target=$1

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/opt/homebrew/opt/gettext/bin:/usr/local/opt/gettext/bin:${PATH}"

  macos_flags="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_OSX_ARCHITECTURES=arm64\;x86_64"
  #macos_flags="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_OSX_ARCHITECTURES=arm64"

  pushd ../Neovim

  # W/o setting MACOSX_DEPLOYMENT_TARGET, the dependencies have min. macOS set to the macOS you're on.
  make \
    CMAKE_BUILD_TYPE=Release \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CMAKE_EXTRA_FLAGS="" \
    CMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    DEPS_CMAKE_FLAGS="${macos_flags}" \
    libnvim nvim 

  popd
}

main() {
  # This script is located in /NvimServer/bin and we have to go to /
  echo "$(dirname "${BASH_SOURCE[0]}")/../../"
  pushd "$(dirname "${BASH_SOURCE[0]}")/../../" >/dev/null

  echo "### Building libnvim"
  local deployment_target
  deployment_target=$(jq -r .deploymentTarget ./NvimServer/Resources/buildInfo.json)
  readonly deployment_target

  if [[ "${clean}" == true ]]; then
    pushd ../Neovim
    make distclean
    popd

    ./NvimServer/bin/prepare_libintl.sh

  fi

  build_libnvim "${deployment_target}"

  popd >/dev/null
  echo "### Built libnvim"
}

main

