#!/bin/bash

set -e
set -x

echo "### Building libnvim"

pushd neovim

ln -f -s ../local.mk .

rm -rf build
make distclean

echo "### Building libnvim"
make libnvim

popd

echo "### Updating carthage"
carthage update --platform osx --cache-builds

echo "### Executing tests"
xcodebuild test -scheme SwiftNeoVim
xcodebuild test -scheme VimR
