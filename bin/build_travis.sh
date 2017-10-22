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

# to avoid Xcode time out, cf https://stackoverflow.com/questions/37922146/xctests-failing-on-physical-device-canceling-tests-due-to-timeout/40790171#40790171
echo "### Building"
xcodebuild build -scheme SwiftNeoVim
xcodebuild build -scheme VimR

echo "### Executing tests"
xcodebuild test -scheme SwiftNeoVim
xcodebuild test -scheme VimR
