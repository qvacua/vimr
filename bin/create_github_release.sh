#!/bin/bash

set -e

TOKEN=$(cat ~/.local/secrets/github.qvacua.release.token)

COMPOUND_VERSION=$1
TAG=$2
VIMR_FILE_NAME=$3
RELEASE_NOTES=$4
IS_SNAPSHOT=$5

echo "COMPOUND_VERSION: ${COMPOUND_VERSION}"
echo "TAG: ${TAG}"
echo "VIMR_FILE_NAME: ${VIMR_FILE_NAME}"
echo "RELEASE_NOTES: ${RELEASE_NOTES}"
echo "IS_SNAPSHOT: ${IS_SNAPSHOT}"

pushd build/Build/Products/Release

echo "### Creating release"
if [ "${IS_SNAPSHOT}" = true ] ; then
    GITHUB_TOKEN="${TOKEN}" github-release release \
        --user qvacua \
        --repo vimr \
        --tag "${TAG}" \
        --pre-release \
        --name "${COMPOUND_VERSION}" \
        --description "${RELEASE_NOTES}"
else
    GITHUB_TOKEN="${TOKEN}" github-release release \
        --user qvacua \
        --repo vimr \
        --tag "${TAG}" \
        --name "${COMPOUND_VERSION}" \
        --description "${RELEASE_NOTES}"
fi


echo "### Uploading build"
GITHUB_TOKEN="${TOKEN}" github-release upload \
    --user qvacua \
    --repo vimr \
    --tag "${TAG}" \
    --name "${VIMR_FILE_NAME}" \
    --file "${VIMR_FILE_NAME}"
