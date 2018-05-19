#!/bin/bash

set -e

git submodule update

pushd NvimView/neovim
major=$(grep -e "set(NVIM_VERSION_MAJOR" CMakeLists.txt | gsed -E "s/.*([0-9]+).*/\1/")
minor=$(grep -e "set(NVIM_VERSION_MINOR" CMakeLists.txt | gsed -E "s/.*([0-9]+).*/\1/")
patch=$(grep -e "set(NVIM_VERSION_PATCH" CMakeLists.txt | gsed -E "s/.*([0-9]+).*/\1/")
prerelease=$(grep -e "set(NVIM_VERSION_PRERELEASE" CMakeLists.txt | gsed -E "s/.*\(.*\"(.*)\"\).*/\1/")
nvim_version="v$major.$minor.$patch$prerelease"
echo $nvim_version

../../bin/build_libnvim.sh
popd

pushd NvimView
VERSION=${nvim_version} ../bin/generate_autocmds.py
popd

echo "############## Successfully generated sources."
