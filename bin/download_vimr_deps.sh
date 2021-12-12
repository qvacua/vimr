#!/bin/bash
set -Eeuo pipefail

readonly target_dir_path="VimR/.deps"
readonly file_name="vimr-deps"
readonly compressed_file_name="${file_name}.tar.bz2"

download_vimr_deps() {
  echo "### Downloading ${file_name}"
  local version
  version=$(cat ./resources/vimr-deps_version.txt)
  readonly version

  echo "#### Downloading ${version}"

  rm -rf "${target_dir_path}"

  mkdir -p ${target_dir_path}
  curl -o "${target_dir_path}/vimr-deps.tar.bz2" -L "https://github.com/qvacua/vimr/releases/download/${version}/${compressed_file_name}"

  pushd ${target_dir_path} >/dev/null
    tar xf "${compressed_file_name}"
    rm ${compressed_file_name}
    mv "${file_name}"/* .
    rm -r "${file_name}"
  popd >/dev/null

  echo "### Downloaded ${file_name}"
}

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null
    download_vimr_deps
  popd >/dev/null
}

main