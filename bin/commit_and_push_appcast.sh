#!/bin/bash
set -Eeuo pipefail

echo "### Commit and push appcast"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

readonly branch=${branch:?"Eg develop"}
readonly compound_version=${compound_version:?"Eg v0.29.0-329"}
readonly is_snapshot=${is_snapshot:?"true or false"}
readonly update_snapshot_appcast_for_release=${update_snapshot_appcast_for_release:?"true or false"}

if [[ ${is_snapshot} == true ]] ; then
    cp ./build/Build/Products/Release/appcast_snapshot.xml .
else
    cp ./build/Build/Products/Release/appcast.xml .
fi

if [[ ${is_snapshot} == false ]] && [[ ${update_snapshot_appcast_for_release} == true ]]; then
    cp appcast.xml appcast_snapshot.xml
fi

echo "### Commiting and pushing appcast(s) to ${branch}"

git add appcast*
git commit -m "Bump appcast(s) to ${compound_version}"
git push origin HEAD:"${branch}"

popd > /dev/null
echo "### Committed and pushed appcast(s)"
