#!/bin/bash
set -Eeuo pipefail

readonly nvim_install_path=${nvim_install_path:?"where to install temp nvim"}

build_runtime() {
  local -r deployment_target=$1

  echo "#### runtime in ${nvim_install_path}"

  echo "### Building nvim to get the complete runtime"
  make \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CMAKE_EXTRA_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=${nvim_install_path}" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target}" \
    CMAKE_BUILD_TYPE="Release" \
    install

  echo "#### runtime is installed at ${nvim_install_path}/share/nvim/runtime"
}

main() {
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  echo "### Building runtime"
  local deployment_target
  deployment_target=$(jq -r .deploymentTarget ./NvimServer/Resources/buildInfo.json)
  readonly deployment_target

  build_runtime "${deployment_target}"

  popd >/dev/null
  echo "### Built runtime"
}

main
