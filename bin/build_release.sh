#!/bin/bash
set -Eeuo pipefail

# The release spec file should export the following env vars:
# is_snapshot
# bundle_version
# marketing_version
# tag
# github_release_name
# release_notes
readonly release_spec_file=${release_spec_file:?"path to release spec sh file (output by set_new_versions.sh script"}

source "${release_spec_file}"

readonly build_folder_path="./build/Build/Products/Release"
readonly vimr_artifact_path="${build_folder_path}/VimR-${marketing_version}.tar.bz2"

check_version() {
  if [[ "${is_snapshot}" == true && ! "${marketing_version}" =~ ^SNAPSHOT.* ]]; then
    echo "When snapshot, marketing_version should be SNAPSHOT-xyz"
    exit 1
  fi

  if [[ "${is_snapshot}" == false && ! "${marketing_version}" =~ ^v.* ]]; then
    echo "When no snapshot, marketing_version should be like v0.35.0"
    exit 1
  fi
}

build_release() {
  echo "### Building release"

  # Check whether NvimServer submodule is clean
  git submodule update
  pushd Neovim >/dev/null
    if [[ ! -z "$(git status --porcelain)" ]]; then
      echo "NvimServer submodule not clean!"
      exit 1
    fi
  popd >/dev/null

  is_jenkins=${is_jenkins:-false} clean=true notarize=true ./bin/build_vimr.sh

  pushd "${build_folder_path}" >/dev/null
    tar cjf "VimR-${marketing_version}.tar.bz2" VimR.app
  popd >/dev/null
  echo "### Built (signed and notarized) release: ${vimr_artifact_path}"
}

main() {
  echo "vimr_artifact_path=${vimr_artifact_path}"

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

    check_version
    build_release

  popd >/dev/null
}

main
