#!/bin/bash

set -e

IS_SNAPSHOT=$1
MARKETING_VERSION=$2

echo "### Setting versions of VimR"

pushd VimR

# bundle version
agvtool bump -all
BUNDLE_VERSION=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')

# marketing version
if [ "${IS_SNAPSHOT}" = true ] ; then
    MARKETING_VERSION="SNAPSHOT-${BUNDLE_VERSION}"
fi

agvtool new-marketing-version ${MARKETING_VERSION}

popd

for proj in 'MsgPackRpc' 'NvimMsgPack' 'NvimView'; do
    pushd ${proj}
    agvtool new-version -all ${BUNDLE_VERSION}
    agvtool new-marketing-version ${MARKETING_VERSION}
    popd
done

echo "### Set versions of VimR"
