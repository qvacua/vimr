#!/bin/bash
set -Eeuo pipefail

readonly branch=${branch:?"which branch to use"}
declare -r -x create_gh_release=${create_gh_release:?"create Github release?"}
declare -r -x upload=${upload:?"upload artifact to github release?"}
declare -r -x update_appcast=${update_appcast:?"update and push appcast?"}

# release.spec.sh will declare these two variables
release_notes=${release_notes:?"release notes"}
is_snapshot=${is_snapshot:?"is snapshot?"}

check_parameters() {
  if [[ "${is_snapshot}" == false && -z "${marketing_version}" ]]; then
    echo "### No marketing_version for a release version! Exiting"
    exit 1
  fi

  if [[ "${create_gh_release}" == true && -z "${release_notes}" ]]; then
    echo "### No release notes when creating github release! Exiting"
    exit 1
  fi
}

main() {
  echo "### Releasing VimR started"

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  check_parameters

  git submodule update --init
  git checkout "${branch}"
  git pull

  ./bin/set_new_versions.sh

  echo "### Store release notes"
  echo "${release_notes}" > release-notes.temp.md

  # get the marketing version to be used as tag
  source release.spec.sh

  if [[ "${is_snapshot}" == true ]]; then
    tag_name="snapshot/${bundle_version}"
  else
    tag_name="${marketing_version}-${bundle_version}"
  fi
  echo "### Using ${tag_name} as tag name"

  echo "### Build VimR"

  is_jenkins=true release_spec_file=release.spec.sh ./bin/build_release.sh

  echo "### Commit and push the tag"
  git commit -am "Bump version to ${tag_name}"
  git tag -a "${tag_name}" -m "${tag_name}"
  git push
  git push origin "${tag_name}"

  if [[ "${create_gh_release}" == false ]]; then
    echo "### No github release, so exiting after building"
    exit 0
  fi

  echo "### Publish VimR to GitHub"

  release_spec_file=release.spec.sh \
  ./bin/publish_release.sh

  echo "### Commit appcast"
  if [[ "${update_appcast}" == true ]]; then
    if [[ "${is_snapshot}" == false ]]; then
      cp appcast.xml appcast_snapshot.xml
    fi

    git commit appcast* -m "Update appcast"
    git push
  fi

  popd >/dev/null

  echo "### Releasing VimR ended"
}

main

