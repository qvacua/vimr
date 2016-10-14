#!/bin/bash

BRANCH=$1
TAG_NAME=$2
RELEASE_VERSION=$3

echo "### Committing version bump"
git commit -am "Bump version: ${RELEASE_VERSION}"

echo "### Tagging VimR"
git tag -a -m "${MARKETING_VERSION} (${BUNDLE_VERSION})" "${TAG_NAME}"

echo "### Pushing commit and tag to vimr repository"
echo git push origin HEAD:${BRANCH}
echo git push origin ${TAG_NAME}

pushd neovim

echo "### Tagging neovim"
git tag -a -m "${MARKETING_VERSION} (${BUNDLE_VERSION})" "${TAG_NAME}"

echo "### Pushing tag to neovim repository"
echo git push origin ${TAG_NAME}

popd neovim
