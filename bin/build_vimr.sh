#!/bin/bash
set -Eeuo pipefail

readonly code_sign=${code_sign:?"true or false"}
readonly use_carthage_cache=${use_carthage_cache:?"true or false"}
readonly download_deps=${download_deps:?"true or false: when true, vimr-deps is downloaded"}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  echo "### Building VimR target"

  if [[ "${download_deps}" == true ]]; then
    rm -rf ./VimR/.deps
    ./bin/download_vimr_deps.sh
  fi

  local -r build_path="./build"

  # Carthage often crashes => do it at the beginning.
  echo "### Updating carthage"
  if [[ "${use_carthage_cache}" == true ]]; then
    carthage update --cache-builds --platform macos
  else
    carthage update --platform macos
  fi

  ./bin/download_nvimserver.sh

  echo "### Xcodebuilding"
  rm -rf ${build_path}

  xcodebuild -configuration Release -derivedDataPath ${build_path} \
    -workspace VimR.xcworkspace -scheme VimR \
    clean build

  if [[ "${code_sign}" == true ]]; then
      local -r -x vimr_app_path="${build_path}/Build/Products/Release/VimR.app"
      ./bin/sign_vimr.sh
  fi

  echo "### Built VimR target"
  popd >/dev/null
}

main