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

echo "### Cleaned old builds"
