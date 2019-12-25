#!/bin/bash
set -Eeuo pipefail

readonly use_committed_nvim=${use_committed_nvim:?"If true, checkout the committed version of nvim, otherwise use the workspace."}

echo "### Generating autocmds file."
echo "* use_committed_nvim=$use_committed_nvim"

pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

if [[ ${use_committed_nvim} == true ]]; then
    echo "### Using the committed version of neovim."
    git submodule update
else
    echo "### Using the workspace neovim."
fi

pushd NvimView/neovim > /dev/null
    major=$(grep -e "set(NVIM_VERSION_MAJOR" CMakeLists.txt | gsed -E "s/.*([0-9]+).*/\1/")
    minor=$(grep -e "set(NVIM_VERSION_MINOR" CMakeLists.txt | gsed -E "s/.*([0-9]+).*/\1/")
    patch=$(grep -e "set(NVIM_VERSION_PATCH" CMakeLists.txt | gsed -E "s/.*([0-9]+).*/\1/")
    prerelease=$(grep -e "set(NVIM_VERSION_PRERELEASE" CMakeLists.txt | gsed -E "s/.*\(.*\"(.*)\"\).*/\1/")
    nvim_version="v$major.$minor.$patch$prerelease"
    echo "### Using nvim version: $nvim_version"

    ../../bin/build_libnvim.sh
popd > /dev/null

pushd NvimView
    version=${nvim_version} ../bin/generate_autocmds.py
popd > /dev/null

popd > /dev/null

echo "### Successfully generated autocmds."
