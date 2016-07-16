#!/bin/bash

set -e

export PATH=/usr/local/bin:$PATH

# delete previously built VimR
rm -rf build

git submodule update --init

# delete previously built libnvim
pushd neovim
ln -f -s ../local.mk .
rm -r build
make clean
make CMAKE_BUILD_TYPE=Release libnvim
popd

carthage update --platform osx

./bin/bump_bundle_version.sh
./bin/set_snapshot_date.sh

xcodebuild CODE_SIGN_IDENTITY="Developer ID Application: Tae Won Ha (H96Q2NKTQH)"

git commit -am "Set snapshot version: $(./bin/current_marketing_version.sh)-$(./bin/current_bundle_version.sh)"
git tag -a -m "$(./bin/current_marketing_version.sh) ($(./bin/current_bundle_version.sh))" snapshot/$(date +%Y%m%d.%H%M)-$(./bin/current_bundle_version.sh)

pushd build/Release
tar cjf VimR-$(./bin/current_marketing_version.sh).tar.bz2 VimR.app
tar cjf SwiftNeoVim.framework-$(./bin/current_marketing_version.sh).tar.bz2 SwiftNeoVim.framework
popd