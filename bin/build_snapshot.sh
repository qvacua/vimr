#!/bin/bash

set -e

export PATH=/usr/local/bin:$PATH

# delete all (local) tags
git tag | xargs git tag -d

# delete all (local) branches
git for-each-ref --format="%(refname:strip=2)" refs/heads/ | xargs git branch -D
git checkout -b build_snapshot

# delete previously built VimR
xcodebuild clean
rm -rf build

git submodule update --init

# delete previously built libnvim
pushd neovim
ln -f -s ../local.mk .
rm -rf build
make distclean
make CMAKE_BUILD_TYPE=Release libnvim
popd

carthage update --platform osx

./bin/bump_bundle_version.sh
./bin/set_snapshot_date.sh

xcodebuild CODE_SIGN_IDENTITY="Developer ID Application: Tae Won Ha (H96Q2NKTQH)" -configuration Release -target VimR

CUR_MARKETING_VERSION=$(./bin/current_marketing_version.sh)
CUR_BUNDLE_VERSION=$(./bin/current_bundle_version.sh)
RELEASE_VERSION="$CUR_MARKETING_VERSION-$CUR_BUNDLE_VERSION"
SNAPSHOT_DATE=$(date +%Y%m%d.%H%M)
TAG_NAME=snapshot/${SNAPSHOT_DATE}-${CUR_BUNDLE_VERSION}

git commit -am "Set snapshot version: $RELEASE_VERSION"
git tag -a -m "$CUR_MARKETING_VERSION ($CUR_BUNDLE_VERSION)" snapshot/${SNAPSHOT_DATE}-${CUR_BUNDLE_VERSION}

pushd build/Release
tar cjf VimR-${RELEASE_VERSION}.tar.bz2 VimR.app
tar cjf SwiftNeoVim.framework-${RELEASE_VERSION}.tar.bz2 SwiftNeoVim.framework
echo ${RELEASE_VERSION} > "$RELEASE_VERSION"
popd

git push origin HEAD:${BRANCH}
git push origin ${TAG_NAME}
