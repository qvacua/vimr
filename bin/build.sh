#!/bin/bash

# For jenkins

set -e

# for utf-8 for python script
export LC_CTYPE=en_US.UTF-8
export PATH=/usr/local/bin:$PATH

# # parameters
# - BRANCH
# - IS_SNAPSHOT
# - MARKETING_VERSION
# - RELEASE_NOTES
# - UPDATE_APPCAST

if [ "${IS_SNAPSHOT}" = false ] && [ "${MARKETING_VERSION}" == "" ] ; then
    echo "### ERROR If not snapshot, then the marketing version must be set!"
    exit 1
fi

if [ "${PUBLISH}" = true ] && [ "${RELEASE_NOTES}" == "" ] ; then
    echo "### ERROR No release notes, but publishing to Github!"
    exit 1
fi

if [ "${IS_SNAPSHOT}" = false ] && [ "${UPDATE_APPCAST}" = false ] ; then
    echo "### ERROR Not updating appcast for release!"
    exit 1
fi

if [ "${IS_SNAPSHOT}" = false ] && [ "${BRANCH}" != "master" ] ; then
    echo "### ERROR Not building master for release!"
    exit 1
fi

if [ "${IS_SNAPSHOT}" = true ] && [ "${BRANCH}" == "master" ] ; then
    echo "### ERROR Building master for snapshot!"
    exit 1
fi

echo "### Installing some python packages"

pip2 install requests
pip2 install Markdown

echo "### Building VimR"

./bin/prepare_repositories.sh
./bin/clean_old_builds.sh

if [ "${PUBLISH}" = true ] ; then
    ./bin/set_new_versions.sh ${IS_SNAPSHOT} "${MARKETING_VERSION}"
else
    echo "Not publishing => not incrementing the version..."
fi

./bin/build_vimr.sh true

BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/')
COMPOUND_VERSION="v${MARKETING_VERSION}-${BUNDLE_VERSION}"
TAG=${COMPOUND_VERSION}

if [ "${IS_SNAPSHOT}" = true ] ; then
    COMPOUND_VERSION="SNAPSHOT-${BUNDLE_VERSION}"
    TAG="snapshot/${BUNDLE_VERSION}"
fi

echo "### Compressing the app"
VIMR_FILE_NAME="VimR-${COMPOUND_VERSION}.tar.bz2"
pushd build/Build/Products/Release
tar cjf ${VIMR_FILE_NAME} VimR.app
popd

echo "### Bundle version: ${BUNDLE_VERSION}"
echo "### Marketing version: ${MARKETING_VERSION}"
echo "### Compund version: ${COMPOUND_VERSION}"
echo "### Tag: ${TAG}"
echo "### VimR archive file name: ${VIMR_FILE_NAME}"

if [ "${PUBLISH}" = false ] ; then
    echo "Do not publish => exiting now..."
    exit 0
fi

./bin/commit_and_push_tags.sh "${BRANCH}" "${TAG}"
./bin/create_github_release.sh "${COMPOUND_VERSION}" "${TAG}" "${VIMR_FILE_NAME}" "${RELEASE_NOTES}" ${IS_SNAPSHOT}

if [ "${UPDATE_APPCAST}" = true ] ; then
    ./bin/set_appcast.py "build/Build/Products/Release/${VIMR_FILE_NAME}" "${BUNDLE_VERSION}" "${MARKETING_VERSION}" "${TAG}" ${IS_SNAPSHOT}
    ./bin/commit_and_push_appcast.sh "${BRANCH}" "${COMPOUND_VERSION}" ${IS_SNAPSHOT} ${UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE}
fi

if [ "${IS_SNAPSHOT}" = false ] ; then
    echo "### Merging ${BRANCH} back to develop"
    git reset --hard @
    git fetch origin
    git checkout -b for_master_to_develop origin/develop
    git merge --ff-only for_build
    git push origin HEAD:develop
fi

echo "### Built VimR"
