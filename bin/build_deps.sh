#!/bin/bash
set -Eeuo pipefail

readonly target=${target:?"arm64 or x86_64"}

main () {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null
    local -r x86_64_deployment_target=$(cat ./resources/x86_64_deployment_target.txt)
    local -r arm64_deployment_target=$(cat ./resources/arm64_deployment_target.txt)

    local -r pcre_version="8.43"
    local -r xz_version="5.2.4"
    local -r ag_version="2.2.0"

    pushd ./third-party >/dev/null
      python3 build.py \
          --target="${target}" \
          --arm64-deployment-target="${arm64_deployment_target}" \
          --x86_64-deployment-target="${x86_64_deployment_target}" \
          --xz-version "${xz_version}" \
          --pcre-version "${pcre_version}" \
          --ag-version "${ag_version}"
    popd >/dev/null
  popd >/dev/null
}

main
