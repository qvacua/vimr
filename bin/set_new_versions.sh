#!/bin/bash
set -Eeuo pipefail

readonly is_snapshot=${is_snapshot:?"true or false"}
marketing_version=${marketing_version:-""}

main() {
  if [[ "${is_snapshot}" == false && -z "${marketing_version}" ]]; then
    echo "When no snapshot, you have to set 'marketing_version', eg v0.38.1"

    if [[ "${marketing_version}" =~ ^v.* ]]; then
      echo "### marketing_version must not begin with v!"
      exit 1
    fi

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

    pushd VimR >/dev/null
      agvtool new-version -all "${bundle_version}"
      agvtool new-marketing-version "${marketing_version}"
    popd >/dev/null

  popd >/dev/null
  echo "### Set versions of VimR"

  local tag
  local github_release_name
  local version_marker
  if [[ "${is_snapshot}" == true ]]; then
    tag="snapshot/${bundle_version}"
    github_release_name="${marketing_version}"
    version_marker="snapshot"
  else
    tag="v${marketing_version}-${bundle_version}"
    github_release_name="$tag"
    version_marker="release"
    marketing_version="v${marketing_version}"
  fi
  readonly tag
  readonly github_release_name
  readonly version_marker
  readonly marketing_version

  local output
  output=$(cat <<-END
declare -r -x is_snapshot=${is_snapshot}
declare -r -x bundle_version=${bundle_version}
declare -r -x marketing_version=${marketing_version}
declare -r -x tag=${tag}
declare -r -x github_release_name=${github_release_name}
declare -r -x release_notes=\$(cat release-notes.temp.md)

# Add release notes to release-notes.temp.md and issue
# create_gh_release=true upload=true update_appcast=true release_spec_file=release.spec.sh ./bin/build_release.sh
END
)
  readonly output

  local output_exec
  output_exec=$(cat <<-END
create_gh_release=true upload=true update_appcast=true release_spec_file=release.spec.sh ./bin/build_release.sh
END
)
  readonly output_exec

  echo "Release notes" > release-notes.temp.md
  echo "${output}" > "release.spec.sh"
  echo "${output_exec}" > "build_release.temp.sh"
  chmod +x "build_release.temp.sh"

  echo "### Tag, commit and push with ${tag}."
  echo "Then, add release notes to release-notes.temp.md."
  echo ""
  echo "### Use the following to build a release:"
  echo ""
  echo "release_spec_file=release.spc.sh \\"
  echo "create_gh_release=true upload=true update_appcast=true \\"
  echo "./bin/build_release.sh"
  echo ""
  echo "OR do build_release.temp.sh"
}

main
