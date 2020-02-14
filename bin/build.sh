#!/bin/bash
set -Eeuo pipefail

echo "### Building in Jenkins"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

# for utf-8 for python script
export LC_CTYPE=en_US.UTF-8
export PATH=/usr/local/bin:$PATH

readonly publish=${publish:?"true or false"}
readonly branch=${branch:?"Eg develop"}
readonly is_snapshot=${is_snapshot:?"true or false"}
readonly update_appcast=${update_appcast:?"true or false"}
readonly update_snapshot_appcast_for_release=${update_snapshot_appcast_for_release:?"true or false"}

export marketing_version=${marketing_version:-"SNAPSHOT"}
readonly release_notes=${release_notes:-""}

readonly use_cache_carthage=${use_cache_carthage:?"true of false"}

if [[ "${is_snapshot}" = false ]] && [[ "${marketing_version}" == "" ]] ; then
    echo "### ERROR If not snapshot, then the marketing version must be set!"
    exit 1
fi

if [[ "${publish}" == true ]] && [[ "${release_notes}" == "" ]] ; then
    echo "### ERROR No release notes, but publishing to Github!"
    exit 1
fi

if [[ "${is_snapshot}" == false ]] && [[ "${update_appcast}" == false ]] ; then
    echo "### ERROR Not updating appcast for release!"
    exit 1
fi

if [[ "${is_snapshot}" == false ]] && [[ "${branch}" != "master" ]] ; then
    echo "### ERROR Not building master for release!"
    exit 1
fi

if [[ "${is_snapshot}" == true ]] && [[ "${branch}" == "master" ]] ; then
    echo "### ERROR Building master for snapshot!"
    exit 1
fi

git lfs install

echo "### Installing some python packages"

pip3 install requests
pip3 install Markdown
pip3 install waiting

echo "### Building VimR"

./bin/prepare_repositories.sh
./bin/clean_old_builds.sh

if [[ "${is_snapshot}" == false ]] || [[ "${publish}" == true ]] ; then
    ./bin/set_new_versions.sh
else
    echo "Not publishing and no release => not incrementing the version..."
fi

code_sign=true use_carthage_cache=${use_cache_carthage} ./bin/build_vimr.sh

pushd VimR > /dev/null
    export readonly bundle_version=$(agvtool what-version | sed '2q;d' | sed -E 's/ +(.+)/\1/')
    export marketing_version=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/')
popd > /dev/null


if [[ "${is_snapshot}" == true ]]; then
    export readonly compound_version="SNAPSHOT-${bundle_version}"
    export readonly tag="snapshot/${bundle_version}"
else
    export readonly compound_version="v${marketing_version}-${bundle_version}"
    export readonly tag=${compound_version}
fi

echo "### Compressing the app"
export readonly vimr_file_name="VimR-${compound_version}.tar.bz2"

pushd build/Build/Products/Release > /dev/null
  tar cjf ${vimr_file_name} VimR.app
popd > /dev/null

echo "### Bundle version: ${bundle_version}"
echo "### Marketing version: ${marketing_version}"
echo "### Compund version: ${compound_version}"
echo "### Tag: ${tag}"
echo "### VimR archive file name: ${vimr_file_name}"

echo "### Notarizing"
pushd ./build/Build/Products/Release > /dev/null
    ditto -c -k --keepParent VimR.app VimR.app.zip
    echo "### Uploading"
    export readonly request_uuid=$(xcrun \
        altool --notarize-app --primary-bundle-id "com.qvacua.VimR" \
        --username "hataewon@gmail.com" --password "@keychain:dev-notar" \
        --file VimR.app.zip | grep RequestUUID | sed -E 's/.* = (.*)/\1/')
popd > /dev/null

echo "### Waiting for notarization ${request_uuid} to finish"
./bin/wait_for_notarization.py
echo "### Notarization finished"

pushd ./build/Build/Products/Release > /dev/null
    rm -rf ${vimr_file_name}
    xcrun stapler staple VimR.app
    tar cjf ${vimr_file_name} VimR.app
popd > /dev/null

if [[ "${publish}" == false ]] ; then
    echo "Do not publish => exiting now..."
    exit 0
fi

./bin/commit_and_push_tags.sh
./bin/create_github_release.sh

if [[ "${update_appcast}" == true ]]; then
    ./bin/set_appcast.py "build/Build/Products/Release/${vimr_file_name}" "${bundle_version}" "${marketing_version}" "${tag}" ${is_snapshot}
    ./bin/commit_and_push_appcast.sh "${branch}" "${compound_version}" ${is_snapshot} ${update_snapshot_appcast_for_release}
fi

if [[ "${is_snapshot}" == false ]] ; then
    echo "### Merging ${branch} back to develop"
    git reset --hard @
    git fetch origin
    git checkout -b for_master_to_develop origin/develop
    git merge --ff-only for_build
    git push origin HEAD:develop
fi

popd > /dev/null
echo "### Built VimR"
