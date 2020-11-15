#!/bin/bash
set -Eeuo pipefail

readonly target_dir_path="Carthage/Build/Mac"
readonly nvimserver_dir_path="${target_dir_path}/NvimServer"

download_nvimserver() {
  echo "### Downloading NvimServer"
  local version
  version=$(cat ./resources/nvimserver_version.txt)
  readonly version

  echo "#### Downloading ${version}"

  rm -rf ${nvimserver_dir_path}
  rm -rf "${target_dir_path}/NvimServer.tar.bz2"

  mkdir -p ${target_dir_path}
  curl -o "${target_dir_path}/NvimServer.tar.bz2" -L "https://github.com/qvacua/neovim/releases/download/${version}/NvimServer.tar.bz2"

  pushd ${target_dir_path} >/dev/null
  tar xf "NvimServer.tar.bz2"
  popd >/dev/null

  cp -r "${nvimserver_dir_path}/NvimServer" NvimView/Sources/NvimView/
  cp -r "${nvimserver_dir_path}/runtime" NvimView/Sources/NvimView/
  cp NvimView/Sources/NvimView/com.qvacua.NvimView.vim NvimView/Sources/NvimView/runtime/plugin

  echo "### Downloaded NvimServer"
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null
    download_nvimserver
  popd >/dev/null
}

main