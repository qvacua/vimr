#!/bin/bash

set -e

export PATH=/usr/local/bin:$PATH

# # parameters
IS_SNAPSHOT=true
MARKETING_VERSION=$1

# ./bin/prepare_repositories.sh
# ./bin/clean_old_builds.sh
# ./bin/set_new_versions.sh

BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/')

#./bin/build_vimr.sh

# push neovim tag
# commit and push vimr tag


exit 0

# TODO: should be params
MARKETING_VERSION=$(./bin/current_marketing_version.sh)
BUNDLE_VERSION=$(./bin/current_bundle_version.sh)
RELEASE_VERSION="${MARKETING_VERSION}-${BUNDLE_VERSION}"
CURRENT_DATE=$(date +%Y%m%d.%H%M)
TAG_NAME="snapshot/${CURRENT_DATE}-${BUNDLE_VERSION}"

# delete all (local) tags
git tag | xargs git tag -d

# delete all (local) branches
git for-each-ref --format="%(refname:strip=2)" refs/heads/ | xargs git branch -D
git checkout -b for_build

# delete previously built VimR
xcodebuild clean
rm -rf build

git submodule update --init --force

# Build NeoVim
# 0. Delete previously built things
# 1. Build normally to get the full runtime folder and copy it to the neovim's project root
# 2. Delete the build folder to re-configure
# 3. Build libnvim
pushd neovim

ln -f -s ../local.mk .

make distclean

make CMAKE_FLAGS="-DCUSTOM_UI=0"
make CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=/tmp/nvim" install
cp -r /tmp/nvim/share/nvim/runtime .

make clean
rm -rf build

echo "### Building neovim"
make libnvim

echo "### Tagging neovim"
git tag -a -m "${MARKETING_VERSION} (${BUNDLE_VERSION})" "${TAG_NAME}"

popd

echo "### Updating carthage"
carthage update --platform osx

./bin/bump_bundle_version.sh
./bin/set_snapshot_date.sh

echo "### Building VimR"
xcodebuild CODE_SIGN_IDENTITY="Developer ID Application: Tae Won Ha (H96Q2NKTQH)" -configuration Release -target VimR

echo "### Committing version bump"
git commit -am "Set version: ${RELEASE_VERSION}"

echo "### Tagging VimR"
git tag -a -m "${MARKETING_VERSION} (${BUNDLE_VERSION})" "${TAG_NAME}"

pushd build/Release

VIMR_FILE_NAME="VimR-${RELEASE_VERSION}.tar.bz2"

tar cjf "${VIMR_FILE_NAME}" VimR.app
