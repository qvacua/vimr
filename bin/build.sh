#!/bin/bash

# For jenkins

set -e

export PATH=/usr/local/bin:$PATH

# # parameters
# - BRANCH
# - IS_SNAPSHOT
# - MARKETING_VERSION
# - RELEASE_NOTES

echo "### Building VimR"

./bin/prepare_repositories.sh
./bin/clean_old_builds.sh
./bin/set_new_versions.sh ${IS_SNAPSHOT} "${MARKETING_VERSION}"
./bin/build_vimr.sh

BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/')
COMPOUND_VERSION="v${MARKETING_VERSION}-${BUNDLE_VERSION}"
TAG=${COMPOUND_VERSION}
if [ "${IS_SNAPSHOT}" = true ] ; then
    TAG="snapshot/${COMPOUND_VERSION}"
fi
VIMR_FILE_NAME="VimR-${COMPOUND_VERSION}.tar.bz2"

echo "### Bundle version: ${BUNDLE_VERSION}"
echo "### Marketing version: ${MARKETING_VERSION}"
echo "### Compund version: ${COMPOUND_VERSION}"
echo "### Tag: ${TAG}"
echo "### VimR archive file name: ${VIMR_FILE_NAME}"

./bin/commit_and_push_tags.sh "${BRANCH}" "${TAG}"
./bin/create_github_release.sh "${COMPOUND_VERSION}" "${TAG}" "${VIMR_FILE_NAME}" "${RELEASE_NOTES}"
./bin/set_appcast.py "build/Release/${VIMR_FILE_NAME}" "${BUNDLE_VERSION}" "${MARKETING_VERSION}" "${TAG}" ${IS_SNAPSHOT}
./bin/commit_and_push_appcast.sh "${BRANCH}" "${COMPOUND_VERSION}" ${IS_SNAPSHOT}

echo "### Built VimR"
