#!/bin/bash
set -Eeuo pipefail

readonly target=${target:?"arm64 or x86_64"}
readonly clean=${clean:?"true or false: when true, xcodebuild clean will be performed"}

main() {
  if "${clean}" ; then
    local -r cmd="clean build"
  else
    local -r cmd="build"
  fi

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null
    xcodebuild \
      -workspace VimR.xcworkspace \
      -derivedDataPath ./build \
      -configuration Release \
      -scheme VimR -xcconfig \
      ./VimR/Dev.xcconfig \
      ARCHS="${target}" \
      ${cmd}
  popd >/dev/null
}

main