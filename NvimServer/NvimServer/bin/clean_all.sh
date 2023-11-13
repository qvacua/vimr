#!/bin/bash
set -Eeuo pipefail

readonly clean_deps=${clean_deps:-true}

pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
  pushd ../Neovim

  rm -rf ./build
  rm -rf ./.deps
  make distclean

  popd

  if [[ "${clean_deps}" == true ]]; then
    rm -rf ./NvimServer/build
    rm -rf ./NvimServer/third-party
  fi
popd >/dev/null
