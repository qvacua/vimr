#!/bin/bash
set -Eeuo pipefail

readonly create_gh_release=${create_gh_release:?"true or false"}
readonly upload=${upload:?"true or false"}
readonly update_appcast=${update_appcast:?"true or false"}

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
declare -r -x GH_REPO="qvacua/vimr"

prepare_bin() {
  pushd ./bin >/dev/null
    if ! pyenv which python | grep -q "com.qvacua.VimR.bin"; then
      echo "com.qvacua.VimR.bin virtualenv not set up!"
      exit 1;
    fi

    pip install -r requirements.txt
  popd >/dev/null
}

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

check_gh_release_present() {
  if [[ "${upload}" == true ]]; then
    if gh release list | grep "${tag}"; then
      echo "Release with tag ${tag} found"
    else
      echo "Release with tag ${tag} does not exist!"
      exit 1
    fi
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

  clean=true notarize=true ./bin/build_vimr.sh

  pushd "${build_folder_path}" >/dev/null
    tar cjf "VimR-${marketing_version}.tar.bz2" VimR.app
  popd >/dev/null
  echo "### Built (signed and notarized) release: ${vimr_artifact_path}"
}

create_gh_release() {
  if [[ "${is_snapshot}" == true ]]; then
    gh release create "${tag}" \
      --discussion-category "general" \
      --prerelease \
      --title "${github_release_name}" \
      --notes "${release_notes}"
  else
    gh release create "${tag}" \
      --discussion-category "general" \
      --title "${github_release_name}" \
      --notes "${release_notes}"
  fi
}

upload_artifact() {
  echo "### Uploading artifact"
  gh release upload "${tag}" "${vimr_artifact_path}"
  echo "### Uploaded artifact"
}

update_appcast_file() {
  ./bin/set_appcast.py \
      "${vimr_artifact_path}" \
      "${bundle_version}" \
      "${marketing_version}" \
      "${tag}" \
      "${is_snapshot}"

  local app_cast_file_name="appcast.xml"
  if [[ "${is_snapshot}" == true ]]; then
    app_cast_file_name="appcast_snapshot.xml"
  fi
  readonly app_cast_file_name

  cp "${build_folder_path}/${app_cast_file_name}" .
  echo "### ${app_cast_file_name} updated. Commit and push"
}

main() {
  echo "create_gh_release=${create_gh_release} \\"
  echo "upload=${upload} update_appcast=${update_appcast} \\"
  echo "vimr_artifact_path=${vimr_artifact_path}"

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

#    check_version
#    prepare_bin
#    build_release
#
#    if [[ "${create_gh_release}" == false ]]; then
#      echo "### No github release, exiting"
#      exit 0
#    fi
#
#    local -x GH_TOKEN
#    GH_TOKEN=$(cat ~/.local/secrets/github.qvacua.release.token)
#    readonly GH_TOKEN
#
#    create_gh_release
#
#    if [[ "${upload}" == true ]]; then
#      # Give GitHub some time.
#      sleep 5
#      check_gh_release_present
#      upload_artifact
#    fi

    if [[ "${update_appcast}" == true ]]; then
      # Sometimes GitHub is not yet up-to-date with the uploaded asset.
#      sleep 5
      update_appcast_file
    fi

  popd >/dev/null
}

main
