#!/bin/bash
set -Eeuo pipefail

readonly vimr_app_path=${vimr_app_path:?"Path to VimR.app"}

main() {
  pushd "${vimr_app_path}/.." >/dev/null
    echo "### Notarizing"
    ditto -c -k --keepParent VimR.app VimR.app.zip

    echo "### Uploading"
    declare -x request_uuid
    request_uuid=$(xcrun \
      altool --notarize-app --primary-bundle-id "com.qvacua.VimR" \
      --username "hataewon@gmail.com" --password "@keychain:dev-notar" \
      --file VimR.app.zip | grep RequestUUID | sed -E 's/.* = (.*)/\1/')
    readonly request_uuid

    pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
      echo "### Waiting for notarization ${request_uuid} to finish"
      ./bin/wait_for_notarization.py
      echo "### Notarization finished"
    popd >/dev/null

    xcrun stapler staple VimR.app
  popd >/dev/null
}

main