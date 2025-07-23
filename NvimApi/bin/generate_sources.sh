#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false"}
readonly NVIM_PATH="../Neovim/build/bin/nvim"

build_nvimserver_bin() {
  ./bin/neovim/bin/build_neovim_for_dev.sh
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  echo "Make sure you have the correct ref checked out; develop or update-neovim."
  build_nvimserver_bin

  pushd NvimApi >/dev/null
    ./bin/generate_async_api_methods.py
    ./bin/generate_sync_api_methods.py

    swiftformat ./Sources/NvimApi/NvimApi.generated.swift \
                ./Sources/NvimApi/NvimApiSync.generated.swift
  popd >/dev/null

  popd >/dev/null
}

main
