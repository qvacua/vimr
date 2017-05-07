#!/bin/bash

set -e

CODE_SIGN=$1

echo "### Building VimR target"

# Build NeoVim
# 0. Delete previously built things
# 1. Build normally to get the full runtime folder and copy it to the neovim's project root
# 2. Delete the build folder to re-configure
# 3. Build libnvim
pushd neovim

ln -f -s ../local.mk .

rm -rf build
make distclean

echo "### Building nvim to get the complete runtime folder"
rm -rf /tmp/nvim
make CMAKE_FLAGS="-DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=/tmp/nvim" install

rm -rf build
make clean

echo "### Building libnvim"
make CFLAGS='-mmacosx-version-min=10.10' MACOSX_DEPLOYMENT_TARGET=10.10 libnvim

echo "### Copying runtime"
rm -rf runtime
cp -r /tmp/nvim/share/nvim/runtime .

popd

echo "### Updating carthage"
carthage update --platform osx

echo "### Xcodebuilding"

if [ "${CODE_SIGN}" = true ] ; then
    xcodebuild CODE_SIGN_IDENTITY="Developer ID Application: Tae Won Ha (H96Q2NKTQH)" -configuration Release -target VimR
else
    xcodebuild -configuration Release -target VimR
fi

echo "### Built VimR target"
