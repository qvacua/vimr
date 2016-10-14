#!/bin/bash

echo "### Cleaning old builds"

# ## delete previously built VimR
rm -rf build
xcodebuild clean

# ## delete previously built neovim
pushd neovim
rm -rf build
make distclean
popd

echo "### Updating carthage"
carthage update --platform osx

echo "### Cleaned old builds"
