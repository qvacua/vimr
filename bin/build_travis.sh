#!/bin/bash

set -e

echo "### Building libnvim"

pushd neovim

ln -f -s ../local.mk .

rm -rf build
make distclean

../bin/build_libnvim.sh

popd

echo "### Updating carthage"
carthage update --platform osx --cache-builds

echo "### Executing tests"
xcodebuild test -scheme SwiftNeoVim
xcodebuild test -scheme VimR
