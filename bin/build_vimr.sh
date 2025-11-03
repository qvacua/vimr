#!/bin/bash
set -Eeuo pipefail

readonly strip_symbols=${strip_symbols:-true}
readonly notarize=${notarize:?"true or false"}
readonly clean=${clean:?"true or false"}
readonly is_jenkins=${is_jenkins:-false}

build_vimr() {
  local -r build_path=$1
  local plugin_flag=""
  
  if [[ "${is_jenkins}" == true ]]; then
    plugin_flag="-skipPackagePluginValidation"
  fi


  echo "### Xcodebuilding"
  rm -rf "${build_path}"
  if [[ "${clean}" == true ]]; then  
      xcodebuild \
        -configuration Release -derivedDataPath "${build_path}" \
        -workspace VimR.xcworkspace -scheme VimR \
        ${plugin_flag} \
        clean build
  else
      xcodebuild \
        -configuration Release -derivedDataPath "${build_path}" \
        -workspace VimR.xcworkspace -scheme VimR \
        ${plugin_flag} \
        build
  fi
}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  echo "### Building VimR"

  ./bin/build_nvimserver.sh

  local -r build_path="./build"
  build_vimr "${build_path}"

  local -r -x vimr_app_path="${build_path}/Build/Products/Release/VimR.app"

  if [[ "${strip_symbols}" == true ]]; then
    strip -rSTx "${vimr_app_path}/Contents/MacOS/VimR"
    strip -rSx "${vimr_app_path}/Contents/Resources/NvimView_NvimView.bundle/Contents/Resources/NvimServer"
  fi

  if [[ "${notarize}" == true ]]; then
    ./bin/sign_vimr.sh
    ./bin/notarize_vimr.sh
  fi

  echo "### VimR built in ${build_path}/Build/Products/Release/VimR.app"
  popd >/dev/null
}

main
