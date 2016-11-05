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
    MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/' | sed -E "s/^([0-9]+)\.([0-9]+)\.([0-9]+).*/\1.\2.\3-SNAPSHOT-$(date +%Y%m%d.%H%M)/")
fi

agvtool new-marketing-version ${MARKETING_VERSION}

echo "### Set versions of VimR"
