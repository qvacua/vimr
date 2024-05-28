#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false"}

build_nvimserver_bin() {
  ./bin/neovim/bin/build_neovim_for_dev.sh
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  echo "Make sure you have the correct ref checked out; develop or update-neovim."
  build_nvimserver_bin

  pushd RxPack >/dev/null
    NVIM_PATH="../Neovim/build/bin/nvim" ./bin/generate_api_methods.py
    swiftformat ./Sources/RxNeovim/RxNeovimApi.generated.swift
  popd >/dev/null

  popd >/dev/null
}

main
