#!/bin/bash

COMPOUND_VERSION=$1
RELEASE_NOTES=$2

VIMR_FILE_NAME="VimR-${COMPOUND_VERSION}.tar.bz2"

pushd build/Release

tar cjf ${VIMR_FILE_NAME} VimR.app

echo "### Creating release"
GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release release \
    --user qvacua \
    --repo vimr \
    --tag "${COMPOUND_VERSION}" \
    --name "${COMPOUND_VERSION}" \
    --description "${RELEASE_NOTES}" \
    --pre-release

echo "### Uploading build"
GITHUB_TOKEN=$(cat ~/.config/github.qvacua.release.token) github-release upload \
    --user qvacua \
    --repo vimr \
    --tag "${COMPOUND_VERSION}" \
    --name "${VIMR_FILE_NAME}" \
    --file "${VIMR_FILE_NAME}"
