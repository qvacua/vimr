#!/bin/bash
# Executing this script will replace the download step of pre-built NvimServer.
set -Eeuo pipefail
BUILD_DIR=".deps"

pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

mkdir -p ${BUILD_DIR}

target_version=$(cat ./nvim-version.txt | awk '{$1=$1}1')
nvim="./${BUILD_DIR}/nvim-osx64/bin/nvim"
if [[ -f ${nvim} ]] ; then
  version="$($nvim --version | grep ^NVIM | awk '{print $2}')" || "n/a"
else
  version="n/a"
fi

echo "Downloaded version: $version"
echo "Target version: $target_version"

download=false
if [[ "$target_version" == "nightly" ]]; then
  echo "Target version is nightly => Downloading..."
  download=true
else
  if ! [[ "$version" =~ "$target_version".* ]]; then
    echo "Target version differs from the downloaded version => Downloading..."
    download=true
  fi
fi

if [[ "$download" == true ]]; then
  curl -L -o ./${BUILD_DIR}/nvim-macos.tar.gz "https://github.com/neovim/neovim/releases/download/$target_version/nvim-macos.tar.gz"
  echo "Downloaded $target_version"
  pushd ./${BUILD_DIR}
  tar xf nvim-macos.tar.gz
  popd
  echo "Extracted $target_version"
else
  echo "No download necessary"
fi

echo "Generating sources..."
NVIM_PATH="$nvim" ./bin/generate_api_methods.py

popd >/dev/null
echo "Generated sources"
