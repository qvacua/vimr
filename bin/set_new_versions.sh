#!/bin/bash
set -Eeuo pipefail

readonly is_snapshot=${is_snapshot:?"true or false"}
marketing_version=${marketing_version:-""}

main() {
  if [[ "${is_snapshot}" == false && -z "${marketing_version}" ]]; then
    echo "When no snapshot, you have to set 'marketing_version', eg 0.38.1"
    exit 1
  fi

  echo "### Setting versions of VimR"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

    local bundle_version
    bundle_version="$(date "+%Y%m%d.%H%M%S")"
    readonly bundle_version

    if [[ "${is_snapshot}" == true ]]; then
        marketing_version="SNAPSHOT-${bundle_version}"
    fi
    readonly marketing_version

    pushd VimR >/dev/null
      agvtool new-version -all "${bundle_version}"
      agvtool new-marketing-version "${marketing_version}"
    popd >/dev/null

  popd >/dev/null
  echo "### Set versions of VimR"
}

main
