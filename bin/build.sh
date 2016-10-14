#!/bin/bash

# For jenkins

set -e

export PATH=/usr/local/bin:$PATH

# # parameters
# - BRANCH
# - IS_SNAPSHOT
# - MARKETING_VERSION
# - RELEASE_NOTES

./bin/prepare_repositories.sh
./bin/clean_old_builds.sh
./bin/set_new_versions.sh ${IS_SNAPSHOT} "${MARKETING_VERSION}"
./bin/build_vimr.sh

BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/')
COMPOUND_VERSION="v${MARKETING_VERSION}-${BUNDLE_VERSION}"
if [ "${IS_SNAPSHOT}" = true ] ; then
    COMPOUND_VERSION="v${MARKETING_VERSION}-${BUNDLE_VERSION}"
fi
TAG=${COMPOUND_VERSION}
VIMR_FILE_NAME="VimR-${COMPOUND_VERSION}.tar.bz2"

./bin/commit_and_push_tags.sh "${BRANCH}" "${TAG}" ${IS_SNAPSHOT}

./bin/create_github_release.sh "${TAG}" "${VIMR_FILE_NAME}" "${RELEASE_NOTES}"

./bin/set_appcast.py "build/Release/${VIMR_FILE_NAME}" "${BUNDLE_VERSION}" "${MARKETING_VERSION}" "${TAG}" ${IS_SNAPSHOT}
