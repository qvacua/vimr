#!/bin/bash
set -Eeuo pipefail

readonly code_sign=${code_sign:?"true or false"}
readonly use_carthage_cache=${use_carthage_cache:?"true or false"}
readonly clean=${clean:?"true or false"}

prepare_nvimserver() {
  resources_folder="./NvimView/Sources/NvimView/Resources"
  rm -rf "${resources_folder}/NvimServer"
  rm -rf "${resources_folder}/runtime"

  # Create and copy runtime folder
  install_path="$(/usr/bin/mktemp -d -t 'nvim-runtime')"
  nvim_install_path="${install_path}" ./NvimServer/NvimServer/bin/build_runtime.sh
  cp -r "${install_path}/share/nvim/runtime" "${resources_folder}"

  # Copy VimR specific vim file to runtime/plugin folder
  cp "${resources_folder}/com.qvacua.NvimView.vim" "${resources_folder}/runtime/plugin"

  # Build NvimServer and copy
  build_libnvim=true ./NvimServer/NvimServer/bin/build_nvimserver.sh
  cp ./NvimServer/.build/apple/Products/Release/NvimServer "${resources_folder}"
}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  echo "### Building VimR nightly"

  local -r build_path="./build"

  # Carthage often crashes => do it at the beginning.
  echo "### Updating carthage"
  if [[ "${use_carthage_cache}" == true ]]; then
    carthage update --cache-builds --platform macos
  else
    carthage update --platform macos
  fi

  prepare_nvimserver

  echo "### Xcodebuilding"
  rm -rf ${build_path}

  deployment_target="$(jq -r .deploymentTargets.nightly ./resources/buildInfo.json)"
  xcodebuild \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    -configuration Release -derivedDataPath ${build_path} \
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
