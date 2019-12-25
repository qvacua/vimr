#!/bin/bash
set -Eeuo pipefail

echo "### Setting versions of VimR"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

readonly is_snapshot=${is_snapshot:?"true or false"}
marketing_version=${marketing_version:?"0.29.0"}

pushd VimR > /dev/null
    # bundle version
    agvtool bump -all
    readonly bundle_version=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')

    # marketing version
    if [[ ${is_snapshot} == true ]]; then
        marketing_version="SNAPSHOT-${bundle_version}"
    fi

    agvtool new-marketing-version ${marketing_version}
popd > /dev/null

for proj in 'NvimView'; do
    pushd ${proj}
    agvtool new-version -all ${bundle_version}
    agvtool new-marketing-version ${marketing_version}
    popd
done

popd > /dev/null
echo "### Set versions of VimR"
