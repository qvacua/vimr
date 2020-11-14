#!/bin/bash
set -Eeuo pipefail

readonly vimr_app_path=${vimr_app_path:?"Path to VimR.app"}
readonly identity="Developer ID Application: Tae Won Ha (H96Q2NKTQH)"

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
    echo "### Signing VimR"
    local -r entitlements_path=$(realpath ./Carthage/Build/Mac/NvimServer/NvimServer.entitlements)

    codesign --verbose --force -s "${identity}" --deep --timestamp --options=runtime \
      "${vimr_app_path}/Contents/Frameworks/Sparkle.framework/Versions/A/Resources/Autoupdate.app"
    codesign --verbose --force -s "${identity}" --timestamp --options=runtime \
      "${vimr_app_path}/Contents/Frameworks/Sparkle.framework/Versions/A"

    codesign --verbose --force -s "${identity}" --timestamp --options=runtime \
      --entitlements="${entitlements_path}" \
      "${vimr_app_path}/Contents/Resources/NvimView_NvimView.bundle/Contents/Resources/NvimServer"

    codesign --verbose --force -s "${identity}" --deep --timestamp --options=runtime \
      "${vimr_app_path}"
    echo "### Signed VimR"
    echo "### Use 'spctl -a -vvvv ${vimr_app_path}' to verify the signing."
  popd >/dev/null
}

main