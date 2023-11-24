#!/bin/bash
set -Eeuo pipefail

readonly strip_symbols=${strip_symbols:-true}
readonly notarize=${notarize:?"true or false"}
readonly clean=${clean:?"true or false"}

prepare_nvimserver() {
  resources_folder="./NvimView/Sources/NvimView/Resources"
  rm -rf "${resources_folder}/NvimServer"
  rm -rf "${resources_folder}/runtime"

  # Build NvimServer and copy
  ./NvimServer/NvimServer/bin/build_neovim.sh
  pushd ./Neovim/build >/dev/null
    tar -xf nvim-macos.tar.gz
  popd >/dev/null

  cp ./Neovim/build/nvim-macos/bin/nvim "${resources_folder}/NvimServer"

  # Create and copy runtime folder
  cp -r ./Neovim/build/nvim-macos/share/nvim/runtime "${resources_folder}"

  # Copy VimR specific vim file to runtime/plugin folder
  cp "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin"
}

build_vimr() {
  local -r build_path=$1

  echo "### Xcodebuilding"
  rm -rf "${build_path}"
  if [[ "${clean}" == true ]]; then  
      xcodebuild \
        -configuration Release -derivedDataPath "${build_path}" \
        -workspace VimR.xcworkspace -scheme VimR \
        clean build
  else
      xcodebuild \
        -configuration Release -derivedDataPath "${build_path}" \
        -workspace VimR.xcworkspace -scheme VimR \
        build
  fi
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

  echo "### VimR built in ${build_path}/Build/Products/Release/VimR.app"
  popd >/dev/null
}

main
