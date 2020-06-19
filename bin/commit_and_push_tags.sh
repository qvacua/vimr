#!/bin/bash
set -Eeuo pipefail

echo "### Commit and push tags"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

readonly branch=${branch:?"Eg develop"}
readonly tag=${tag:?"v0.29.0-329"}

echo "### Committing version bump"
git commit -am "Bump version: ${tag}"

echo "### tagging VimR"
git tag -m "${tag}" "${tag}"

echo "### Pushing commit and tag to vimr repository"
git push origin HEAD:"${branch}"
git push origin "${tag}"

#pushd NvimView/neovim > /dev/null
#    echo "### tagging neovim"
#    git tag -s -m "vimr/${tag}" "vimr/${tag}"
#
#    echo "### Pushing tag to neovim repository"
#    git push origin "vimr/${tag}"
#popd > /dev/null

popd > /dev/null
echo "### Committed and pushed tags"
