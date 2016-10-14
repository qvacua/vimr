#!/bin/bash

echo "### Setting versions of VimR"

# ## bundle version
agvtool bump -all

# ## marketing version
if [ ${IS_SNAPSHOT} = true ] ; then
    MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/' | sed -E "s/(.*)-SNAPSHOT-.*/\1-SNAPSHOT-$(date +%Y%m%d.%H%M)/")
fi
agvtool new-marketing-version ${MARKETING_VERSION}

echo "### Set versions of VimR"
