#!/bin/bash
set -Eeuo pipefail

readonly notarize=${notarize:?"true or false"}
readonly clean=${clean:?"true or false"}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  echo "### Building VimR nightly"

  ./bin/build_vimr.sh

  local -r build_path="./build"
  pushd "${build_path}/Build/Products/Release" >/dev/null
    tar cjf "VimR-neovim-nightly-unsigned.tar.bz2" VimR.app
    echo "### VimR nightly packaged to ${build_path}/Build/Products/ReleaseVimR-neovim-nightly-unsigned.tar.bz2"
  popd >/dev/null

  echo "### Built VimR nightly"
  popd >/dev/null
}

main
