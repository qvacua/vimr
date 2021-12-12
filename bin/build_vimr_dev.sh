#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false: when true, xcodebuild clean will be performed"}
readonly download_deps=${download_deps:-false}

main() {
  if [[ "${clean}" == true ]]; then
    local -r cmd="clean build"
  else
    local -r cmd="build"
  fi

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null
    if [[ "${download_deps}" == true ]]; then
      rm -rf ./VimR/.deps
      ./bin/download_vimr_deps.sh
    fi

    xcodebuild \
      -workspace VimR.xcworkspace \
      -derivedDataPath ./build \
      -configuration Release \
      -scheme VimR \
      -xcconfig ./VimR/Dev.xcconfig \
      ${cmd}
  popd >/dev/null
}

main
