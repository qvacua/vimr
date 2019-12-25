#!/bin/bash
set -Eeuo pipefail

echo "### Create github release"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

readonly compound_version=${compound_version:?"v0.29.0-329"}
readonly tag=${tag:?"v0.29.0-329"}
readonly vimr_file_name=${vimr_file_name:?"VimR-v0.29.0-329.tar.bz2"}
readonly release_notes=${release_notes:?"Some (multiline) markdown text"}
readonly is_snapshot=${is_snapshot:?"true or false"}

readonly token=$(cat ~/.local/secrets/github.qvacua.release.token)

echo "* compound_version: ${compound_version}"
echo "* tag: ${tag}"
echo "* vimr_file_name: ${vimr_file_name}"
echo "* release_notes: ${release_notes}"
echo "* is_snapshot: ${is_snapshot}"

pushd build/Build/Products/Release > /dev/null
    echo "### Creating release"
    if [[ ${is_snapshot} == true ]]; then
        GITHUB_TOKEN="${token}" github-release release \
            --user qvacua \
            --repo vimr \
            --tag "${tag}" \
            --pre-release \
            --name "${compound_version}" \
            --description "${release_notes}"
    else
        GITHUB_TOKEN="${token}" github-release release \
            --user qvacua \
            --repo vimr \
            --tag "${tag}" \
            --name "${compound_version}" \
            --description "${release_notes}"
    fi

    if [[ -z ${vimr_file_name} ]]; then
         echo "No file to upload; exiting..."
         exit 0
    fi

    echo "### Uploading build"
    GITHUB_TOKEN="${token}" github-release upload \
        --user qvacua \
        --repo vimr \
        --tag "${tag}" \
        --name "${vimr_file_name}" \
        --file "${vimr_file_name}"
popd > /dev/null

popd > /dev/null
echo "### Created github release"
