#!/bin/bash

BUILD_DIR=".deps"

mkdir -p ${BUILD_DIR}

nvim="./${BUILD_DIR}/nvim-osx64/bin/nvim"
version="$($nvim --version | grep ^NVIM | awk '{print $2}')" || "n/a"
target_version=$(cat ./nvim-version.txt | awk '{$1=$1}1')

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
  tar xjf nvim-macos.tar.gz
  popd
  echo "Extracted $target_version"
else
  echo "No download necessary"
fi

echo "Generating sources..."
NVIM_PATH="$nvim" ./bin/generate_api_methods.py
echo "Generated sources"
