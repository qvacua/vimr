#!/bin/bash
set -Eeuo pipefail

readonly is_snapshot=${is_snapshot:?"true or false"}
readonly bundle_version=${bundle_version:?"date '+%Y%m%d.%H%M%S'"}
readonly tag=${tag:?"snapshot/xyz or v0.35.0"}
readonly marketing_version=${marketing_version:?"SNAPSHOT-xyz or v0.35.0 (mind the v-prefix when not snapshot"}
readonly upload=${upload:?"true or false"}
readonly update_appcast=${update_appcast:?"true or false"}
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

check_upload() {
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
  code_sign=true use_carthage_cache=false download_deps=true ./bin/build_vimr.sh

  vimr_app_path="${build_folder_path}/VimR.app" ./bin/notarize_vimr.sh

  pushd "${build_folder_path}" >/dev/null
    tar cjf "VimR-${marketing_version}.tar.bz2" VimR.app
  popd >/dev/null
  echo "### Built (signed and notarized) release: ${vimr_artifact_path}"
}

upload_artifact() {
  local -x GH_TOKEN
  GH_TOKEN=$(cat ~/.local/secrets/github.qvacua.release.token)
  readonly GH_TOKEN

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
  echo "is_snapshot=${is_snapshot} bundle_version=${bundle_version}" \
      "tag=${tag} marketing_version=${marketing_version}" \
      "upload=${upload} update_appcast=${update_appcast}" \
      "vimr_artifact_path=${vimr_artifact_path}"

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
    check_version
    check_upload
    prepare_bin
    build_release

    if [[ "${upload}" == true ]]; then
      upload_artifact
    fi

    if [[ "${update_appcast}" == true ]]; then
      update_appcast_file
    fi
  popd >/dev/null
}

main
