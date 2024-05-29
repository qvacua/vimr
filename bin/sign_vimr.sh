#!/bin/bash
set -Eeuo pipefail

readonly vimr_app_path=${vimr_app_path:?"Path to VimR.app"}
readonly identity="Developer ID Application: Tae Won Ha (H96Q2NKTQH)"

remove_sparkle_xpc () {
  # VimR is not sandboxed, so, remove the XPCs
  # https://sparkle-project.org/documentation/sandboxing/#removing-xpc-services
  rm -rf "${vimr_app_path}/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/org.sparkle-project.InstallerLauncher.xpc"
  rm -rf "${vimr_app_path}/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/org.sparkle-project.Downloader.xpc"
}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
    echo "### Signing VimR"
    local entitlements_path
    entitlements_path=$(realpath ./bin/neovim/resources/NvimServer.entitlements)
    readonly entitlements_path

    remove_sparkle_xpc

    codesign --verbose --force -s "${identity}" --timestamp --options=runtime \
      "${vimr_app_path}/Contents/Frameworks/Sparkle.framework/Versions/B/Autoupdate"

    codesign --verbose --force -s "${identity}" --deep --timestamp --options=runtime \
      "${vimr_app_path}/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app"

    codesign --verbose --force -s "${identity}" --options=runtime \
      "${vimr_app_path}/Contents/Frameworks/Sparkle.framework"

    codesign --verbose --force -s "${identity}" --timestamp --options=runtime \
      --entitlements="${entitlements_path}" \
      "${vimr_app_path}/Contents/Resources/NvimView_NvimView.bundle/Contents/Resources/NvimServer"

    for f in "${vimr_app_path}/Contents/Resources/NvimView_NvimView.bundle/Contents/Resources/runtime/parser"/*; do
      codesign --verbose --force -s "${identity}" --timestamp --options=runtime \
      "${f}"
    done

    codesign --verbose --force -s "${identity}" --deep --timestamp --options=runtime \
      "${vimr_app_path}"

    echo "### Signed VimR"
    echo "### Use 'spctl -a -vvvv ${vimr_app_path}' to verify the signing."
  popd >/dev/null
}

main
