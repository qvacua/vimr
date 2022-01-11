#!/bin/bash
set -Eeuo pipefail

readonly target_dir_path="Carthage/Build/Mac"
readonly nvimserver_dir_path="${target_dir_path}/NvimServer"

download_nvimserver() {
  echo "### Downloading NvimServer"
  local version
  version="$(jq -r .dependencies.nvimServer ./resources/buildInfo.json)"
  readonly version

  echo "#### Downloading ${version}"

  rm -rf ${nvimserver_dir_path}
  rm -rf "${target_dir_path}/NvimServer.tar.bz2"

  mkdir -p ${target_dir_path}
  curl -o "${target_dir_path}/NvimServer.tar.bz2" -L "https://github.com/qvacua/neovim/releases/download/${version}/NvimServer.tar.bz2"

  pushd ${target_dir_path} >/dev/null
  tar xf "NvimServer.tar.bz2"
  popd >/dev/null

  cp -r "${nvimserver_dir_path}/NvimServer" NvimView/Sources/NvimView/Resources
  cp -r "${nvimserver_dir_path}/runtime" NvimView/Sources/NvimView/Resources
  cp NvimView/Sources/NvimView/Resources/com.qvacua.NvimView.vim NvimView/Sources/NvimView/Resources/runtime/plugin

  echo "### Downloaded NvimServer"
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null
    download_nvimserver
  popd >/dev/null
}

main