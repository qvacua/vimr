#!/bin/bash

set -e
set -x

IS_SNAPSHOT=$1
MARKETING_VERSION=$2

echo "### Setting versions of VimR"

# bundle version
agvtool bump -all

# marketing version
if [ "${IS_SNAPSHOT}" = true ] ; then
    BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
    MARKETING_VERSION="SNAPSHOT-${BUNDLE_VERSION}"
fi

agvtool new-marketing-version ${MARKETING_VERSION}

echo "### Set versions of VimR"
