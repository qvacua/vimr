#!/bin/bash

set -e

CODE_SIGN=$1
DEPLOYMENT_TARGET="10.13"

echo "### Building VimR target"

# Build NeoVim
# 0. Delete previously built things
# 1. Build normally to get the full runtime folder and copy it to the neovim's project root
# 2. Delete the build folder to re-configure
# 3. Build libnvim
pushd NvimView/neovim

ln -f -s ../local.mk .

rm -rf build
make distclean

echo "### Building nvim to get the complete runtime folder"
rm -rf /tmp/nvim-runtime
make CFLAGS="-mmacosx-version-min=${DEPLOYMENT_TARGET}" MACOSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET} CMAKE_FLAGS="-DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=/tmp/nvim-runtime" install

rm -rf build
make clean

../../bin/build_libnvim.sh

echo "### Copying runtime"
rm -rf runtime
cp -r /tmp/nvim-runtime/share/nvim/runtime .

popd

echo "### Updating carthage"
carthage update --platform osx

echo "### Xcodebuilding"

if [ "${CODE_SIGN}" = true ] ; then
    xcodebuild CODE_SIGN_IDENTITY="Developer ID Application: Tae Won Ha (H96Q2NKTQH)" -configuration Release -scheme VimR -workspace VimR.xcworkspace -derivedDataPath build
else
    xcodebuild -configuration Release -scheme VimR -workspace VimR.xcworkspace -derivedDataPath build
fi

echo "### Built VimR target"
