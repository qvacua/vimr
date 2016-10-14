#!/bin/bash

BRANCH=$1
COMPOUND_VERSION=$2

echo "### Committing version bump"
git commit -am "Bump version: ${COMPOUND_VERSION}"

echo "### Tagging VimR"
git tag -a -m "${COMPOUND_VERSION}" "${COMPOUND_VERSION}"

echo "### Pushing commit and tag to vimr repository"
echo git push origin HEAD:"${BRANCH}"
echo git push origin "${COMPOUND_VERSION}"

pushd neovim

echo "### Tagging neovim"
git tag -a -m "vimr/${COMPOUND_VERSION}" "vimr/${COMPOUND_VERSION}"

echo "### Pushing tag to neovim repository"
echo git push origin "vimr/${COMPOUND_VERSION}"

popd neovim
