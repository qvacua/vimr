#!/bin/bash

# prerequisites:
# brew install github-release
# echo ${GITHUB_QVACUA_RELEASE_ACCESS_TOKEN} > ~/.config/github.qvacua.release.token
# chmod 700 ~/.config/github.qvacua.release.token

set -e

export PATH=/usr/local/bin:$PATH

CUR_MARKETING_VERSION=$(./bin/current_marketing_version.sh)
CUR_BUNDLE_VERSION=$(./bin/current_bundle_version.sh)
RELEASE_VERSION="$CUR_MARKETING_VERSION-$CUR_BUNDLE_VERSION"
SNAPSHOT_DATE=$(date +%Y%m%d.%H%M)
TAG_NAME=snapshot/${SNAPSHOT_DATE}-${CUR_BUNDLE_VERSION}

# delete all (local) tags
git tag | xargs git tag -d

# delete all (local) branches
git for-each-ref --format="%(refname:strip=2)" refs/heads/ | xargs git branch -D
git checkout -b build_snapshot

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
git tag -a -m "$CUR_MARKETING_VERSION ($CUR_BUNDLE_VERSION)" snapshot/${SNAPSHOT_DATE}-${CUR_BUNDLE_VERSION}

echo "### Pushing tag to neovim repository"
git push origin ${TAG_NAME}

popd

echo "### Updating carthage"
carthage update --platform osx

./bin/bump_bundle_version.sh
./bin/set_snapshot_date.sh

echo "### Building VimR"
xcodebuild CODE_SIGN_IDENTITY="Developer ID Application: Tae Won Ha (H96Q2NKTQH)" -configuration Release -target VimR

echo "### Committing version bump"
git commit -am "Set snapshot version: $RELEASE_VERSION"

echo "### Tagging VimR"
git tag -a -m "$CUR_MARKETING_VERSION ($CUR_BUNDLE_VERSION)" snapshot/${SNAPSHOT_DATE}-${CUR_BUNDLE_VERSION}

pushd build/Release

VIMR_FILE_NAME="VimR-${RELEASE_VERSION}.tar.bz2"

tar cjf ${VIMR_FILE_NAME} VimR.app
tar cjf SwiftNeoVim.framework-${RELEASE_VERSION}.tar.bz2 SwiftNeoVim.framework
echo ${RELEASE_VERSION} > "$RELEASE_VERSION"

echo "### Pushing commit and tag to vimr repository"
git push origin HEAD:${BRANCH}
git push origin ${TAG_NAME}

echo "### Creating release"
GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release release \
    --user qvacua \
    --repo vimr \
    --tag "$TAG_NAME" \
    --name "$RELEASE_VERSION" \
    --description "$RELEASE_NOTES" \
    --pre-release

echo "### Uploading build"
GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release upload \
    --user qvacua \
    --repo vimr \
    --tag "$TAG_NAME" \
    --name "$VIMR_FILE_NAME" \
    --file "$VIMR_FILE_NAME"
