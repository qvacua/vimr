#!/bin/bash
set -Eeuo pipefail

build_nvimserver_bin() {
  clean=true ./NvimServer/bin/build_neovim.sh
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  pushd NvimServer >/dev/null
    echo "Make sure you have the correct ref checked out; develop or update-neovim."
    build_nvimserver_bin
  popd >/dev/null

  pushd RxPack >/dev/null
    NVIM_PATH="../Neovim/build/bin/nvim" ./bin/generate_api_methods.py
  popd >/dev/null

  popd >/dev/null
}

main
