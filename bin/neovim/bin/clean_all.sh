#!/bin/bash
set -Eeuo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")/../../.." >/dev/null
  pushd ./Neovim

  rm -rf ./build
  rm -rf ./.deps
  make distclean

  popd

popd >/dev/null
