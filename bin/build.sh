#!/bin/bash

set -e

export PATH=/usr/local/bin:$PATH

# # parameters
BRANCH=$1
MARKETING_VERSION=$2
IS_SNAPSHOT=$3

#./bin/prepare_repositories.sh
#./bin/clean_old_builds.sh
#./bin/set_new_versions.sh "${MARKETING_VERSION}" ${IS_IS_SNAPSHOT}
#./bin/build_vimr.sh

BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/')
COMPOUND_VERSION="v${MARKETING_VERSION}-${BUNDLE_VERSION}"
if [ ${IS_SNAPSHOT} = true ] ; then
    COMPOUND_VERSION="v${MARKETING_VERSION}-${BUNDLE_VERSION}"
fi

#./bin/commit_and_push_tags.sh "${BRANCH}" "${COMPOUND_VERSION}"

exit 0

pushd build/Release

VIMR_FILE_NAME="VimR-${COMPOUND_VERSION}.tar.bz2"
tar cjf "${VIMR_FILE_NAME}" VimR.app

popd
