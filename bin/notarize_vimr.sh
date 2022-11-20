#!/bin/bash
set -Eeuo pipefail

readonly vimr_app_path=${vimr_app_path:?"Path to VimR.app"}

main() {
  pushd "${vimr_app_path}/.." >/dev/null
    echo "### Notarizing"
    ditto -c -k --keepParent VimR.app VimR.app.zip

    echo "#### Notarizing"
    xcrun notarytool submit VimR.app.zip \
      --keychain-profile  "apple-dev-notar" \
      --wait
  popd >/dev/null

  pushd "${vimr_app_path}/.." >/dev/null
    xcrun stapler staple VimR.app
    echo "### Notarization finished"
  popd >/dev/null
}

main
