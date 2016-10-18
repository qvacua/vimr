#!/bin/bash

set -e

echo "### Cleaning old builds"

rm -rf build
xcodebuild clean

pushd neovim
rm -rf build
make distclean
popd

echo "### Cleaned old builds"
