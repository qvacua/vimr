#!/bin/bash
set -Eeuo pipefail

build_nvimserver_bin() {
  clean=true ./NvimServer/bin/build_libnvim.sh
  swift build -c release --product NvimServer
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  pushd NvimServer >/dev/null
    echo "Make sure you have the correct ref checked out; develop or update-neovim."
    build_nvimserver_bin
  popd >/dev/null

  pushd RxPack >/dev/null
    NVIM_PATH="../NvimServer/.build/release/NvimServer" ./bin/generate_api_methods.py
  popd >/dev/null

  popd >/dev/null
}

main
