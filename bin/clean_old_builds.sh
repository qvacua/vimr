#!/bin/bash

echo "### Cleaning old builds"

rm -rf build
xcodebuild clean

pushd neovim
rm -rf build
make distclean
popd

echo "### Updating carthage"
carthage update --platform osx

echo "### Cleaned old builds"
