#!/bin/bash

set -e

BRANCH=$1
TAG=$2

echo "### Committing version bump"
git commit -S -am "Bump version: ${TAG}"

echo "### Tagging VimR"
git tag -s -m "${TAG}" "${TAG}"

echo "### Pushing commit and tag to vimr repository"
git push origin HEAD:"${BRANCH}"
git push origin "${TAG}"

pushd NvimView/neovim

echo "### Tagging neovim"
git tag -s -m "vimr/${TAG}" "vimr/${TAG}"

echo "### Pushing tag to neovim repository"
git push origin "vimr/${TAG}"

popd
