#!/bin/bash

set -e

echo "### Building libnvim"

pushd neovim

ln -f -s ../local.mk .

rm -rf build
make distclean

echo "### Building libnvim"
CFLAGS='-mmacosx-version-min=10.10' MACOSX_DEPLOYMENT_TARGET=10.10 LibIntl_INCLUDE_DIRS=../third-party/libintl make libnvim

popd

echo "### Updating carthage"
carthage update --platform osx --cache-builds

echo "### Executing tests"
xcodebuild test -scheme SwiftNeoVim
xcodebuild test -scheme VimR
