#!/bin/bash

set -e
set -x

COMPOUND_VERSION=$1
TAG=$2
VIMR_FILE_NAME=$3
RELEASE_NOTES=$4
IS_SNAPSHOT=$5

pushd build/Release

tar cjf ${VIMR_FILE_NAME} VimR.app

echo "### Creating release"
if [ "${IS_SNAPSHOT}" = true ] ; then
    GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release release \
        --user qvacua \
        --repo vimr \
        --tag "${TAG}" \
        --pre-release \
        --name "${COMPOUND_VERSION}" \
        --description "${RELEASE_NOTES}"
else
    GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release release \
        --user qvacua \
        --repo vimr \
        --tag "${TAG}" \
        --name "${COMPOUND_VERSION}" \
        --description "${RELEASE_NOTES}"
fi


echo "### Uploading build"
GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release upload \
    --user qvacua \
    --repo vimr \
    --tag "${TAG}" \
    --name "${VIMR_FILE_NAME}" \
    --file "${VIMR_FILE_NAME}"
