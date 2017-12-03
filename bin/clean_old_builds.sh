#!/bin/bash

set -e

echo "### Cleaning old builds"

rm -rf build
xcodebuild -workspace VimR.xcworkspace -scheme VimR clean -derivedDataPath build

pushd NvimView/neovim
rm -rf build
make distclean
popd

echo "### Cleaned old builds"
