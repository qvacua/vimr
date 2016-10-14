#!/bin/bash

BRANCH=$1
COMPOUND_VERSION=$2
IS_SNAPSHOT=$3
TAG_NAME=$COMPOUND_VERSION

if [ ${IS_SNAPSHOT} = true ] ; then
    TAG_NAME="snapshot/${COMPOUND_VERSION}"
fi

echo "### Committing version bump"
git commit -am "Bump version: ${COMPOUND_VERSION}"

echo "### Tagging VimR"
git tag -a -m "${TAG_NAME}" "${TAG_NAME}"

echo "### Pushing commit and tag to vimr repository"
git push origin HEAD:"${BRANCH}"
git push origin "${TAG_NAME}"

pushd neovim

echo "### Tagging neovim"
git tag -a -m "vimr/${TAG_NAME}" "vimr/${TAG_NAME}"

echo "### Pushing tag to neovim repository"
git push origin "vimr/${TAG_NAME}"

popd neovim
