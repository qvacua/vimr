#!/bin/bash
set -Eeuo pipefail

echo "### Cleaning old builds"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

rm -rf build
xcodebuild -workspace VimR.xcworkspace -derivedDataPath build -scheme VimR clean

pushd NvimView/neovim > /dev/null
    rm -rf build
    make distclean
popd > /dev/null

popd > /dev/null
echo "### Cleaned old builds"
