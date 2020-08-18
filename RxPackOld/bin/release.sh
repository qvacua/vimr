#!/bin/bash

set -e
export PATH=/usr/local/bin:$PATH

# This script is used by Jenkins to release the framework.

# BRANCH = "master"
# PUBLISH = true
# NVIM_VERSION = "v0.2.2"

if [[ "$NVIM_VERSION" == "" ]]; then
  echo "NVIM_VERSION may not be blank: Exiting..."
  exit 1
fi

rm -rf RxNeovimApi.framework.zip

pip3 install msgpack

git checkout -B temporary "origin/$BRANCH"


[[ "$NVIM_VERSION" == "nightly" ]] && nightly=true || nightly=false

if [[ "$nightly" != true ]]; then
  git tag | grep -q $NVIM_VERSION && exists=true || exists=false
  if [[ "$exists" == true && "$OVERRIDE_EXISTING" == false ]]; then
    echo "Release $NVIM_VERSION already exists: Exiting..."
    exit 1
  fi
fi

echo $NVIM_VERSION > nvim-version.txt
git add nvim-version.txt

./bin/generate.sh
git add RxNeovimApi/ApiMethods.generated.swift

token=$(cat ~/.local/secrets/github.qvacua.release.token)
version="$(./.build/nvim-osx64/bin/nvim --version | grep ^NVIM | awk '{print $2}')"
target_version=$NVIM_VERSION
marketing_version=$target_version

if [[ "$nightly" == true ]]; then
  agvtool new-marketing-version "$version"
else
  version=$target_version
  agvtool new-marketing-version "$target_version"
fi
git add RxNeovimApi/Info.plist RxNeovimApiTests/Info.plist

git commit -m "Release $version" || true

carthage update --platform osx
carthage build --no-skip-current --cache-builds --platform osx
carthage archive RxNeovimApi

if [[ "$PUBLISH" != true ]]; then
  echo "Do not publish: Exiting..."
  exit 0
fi

[[ "$target_version" == "nightly" ]] && tag="nightly" || tag=$target_version
echo "Deleting old release ${version}..."
GITHUB_TOKEN="$token" github-release delete \
  --user qvacua \
  --repo RxNeovimApi \
  --tag $tag || true
git push origin :refs/tags/$tag || true

if [[ "$nightly" == true ]]; then
  git tag -fam "Nightly: $version" $tag
else
  git tag -fam "$target_version" $target_version
fi

git push origin temporary:$BRANCH
git push origin $tag

echo "Creating release..."
if [[ "$nightly" == true ]]; then
  GITHUB_TOKEN="$token" github-release release \
    --pre-release \
    --user qvacua \
    --repo RxNeovimApi \
    --tag nightly \
    --name Nightly \
    --description "Nightly: Neovim $version"
else
  GITHUB_TOKEN="${token}" github-release release \
    --user qvacua \
    --repo RxNeovimApi \
    --tag "$target_version" \
    --name "$target_version" \
    --description "Neovim $version"
fi

echo "Uploading build..."
GITHUB_TOKEN="${token}" github-release upload \
  --user qvacua \
  --repo RxNeovimApi \
  --tag $tag \
  --name "RxNeovimApi.framework.zip" \
  --file "RxNeovimApi.framework.zip"
