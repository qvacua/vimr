#!/bin/bash
set -Eeuo pipefail

readonly strip_symbols=${strip_symbols:-true}
readonly notarize=${notarize:?"true or false"}
readonly use_carthage_cache=${use_carthage_cache:?"true or false"}
readonly clean=${clean:?"true or false"}

prepare_nvimserver() {
  resources_folder="./NvimView/Sources/NvimView/Resources"
  rm -rf "${resources_folder}/NvimServer"
  rm -rf "${resources_folder}/runtime"

  # Build NvimServer and copy
  build_libnvim=true ./NvimServer/NvimServer/bin/build_nvimserver.sh
  cp ./Neovim/.build/apple/Products/Release/NvimServer "${resources_folder}"

  # Create and copy runtime folder
  install_path="$(/usr/bin/mktemp -d -t 'nvim-runtime')"
  nvim_install_path="${install_path}" ./NvimServer/NvimServer/bin/build_runtime.sh
  cp -r "${install_path}/share/nvim/runtime" "${resources_folder}"
  rm -rf "${install_path}"

  # Copy VimR specific vim file to runtime/plugin folder
  cp "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin"
}

build_vimr() {
  local -r build_path=$1

  # Carthage often crashes => do it at the beginning.
  echo "### Updating carthage"
  if [[ "${use_carthage_cache}" == true ]]; then
    carthage update --cache-builds --platform macos
  else
    carthage update --platform macos
  fi

  echo "### Xcodebuilding"
  rm -rf "${build_path}"
  xcodebuild \
    -configuration Release -derivedDataPath "${build_path}" \
    -workspace VimR.xcworkspace -scheme VimR \
    clean build
}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  echo "### Building VimR"

  prepare_nvimserver

  local -r build_path="./build"
  build_vimr "${build_path}"

  local -r -x vimr_app_path="${build_path}/Build/Products/Release/VimR.app"

  if [[ "${strip_symbols}" == true ]]; then
    strip -rSTx "${vimr_app_path}/Contents/MacOS/VimR"
  fi

  if [[ "${notarize}" == true ]]; then
    ./bin/sign_vimr.sh
    ./bin/notarize_vimr.sh
  fi

  echo "### VimR built in ${build_path}/Build/Products/VimR.app"
  popd >/dev/null
}

main
