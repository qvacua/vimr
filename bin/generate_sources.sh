#!/bin/bash

set -e

current_neovim_branch=$1

git submodule update

pushd NvimView/neovim
git fetch
make distclean
mv local.mk local.mk.bak || true
git checkout "origin/last-merge-${current_neovim_branch}"
make
popd

nvim_bin_path="./NvimView/neovim/build/bin/nvim"
nvim_version=$(${nvim_bin_path} --version | head -1 | cut -d' ' -f2)

pushd NvimMsgPack
NVIM_PATH="../${nvim_bin_path}" ../bin/generate_api_methods.py
popd

pushd NvimView
VERSION=${nvim_version} ../bin/generate_autocmds.py

pushd neovim
rm -rf build
make clean
git reset --hard HEAD
git checkout ${current_neovim_branch}
mv local.mk.bak local.mk || true
popd

popd

echo "############## Successfully generated sources."
