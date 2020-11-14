#!/bin/bash
set -Eeuo pipefail

readonly code_sign=${code_sign:?"true or false"}
readonly use_carthage_cache=${use_carthage_cache:?"true or false"}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  echo "### Building VimR target"

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

  if [[ "${code_sign}" == true ]]; then
      xcodebuild -configuration Release -derivedDataPath ./build \
        -workspace VimR.xcworkspace -scheme VimR \
        clean build

      local -r -x vimr_app_path="${build_path}/Build/Products/Release/VimR.app"
      ./bin/sign_vimr.sh
  else
      xcodebuild -configuration Release -derivedDataPath ${build_path} \
        -scheme VimR -workspace VimR.xcworkspace \
        clean build
  fi

  echo "### Built VimR target"
  popd >/dev/null
}

main