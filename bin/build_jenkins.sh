#!/bin/bash
set -Eeuo pipefail

readonly branch=${branch:?"which branch to use"}

main() {
  echo "### Releasing VimR started"

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  git submodule update --init

  ./bin/set_new_versions.sh

  # commit and push the tag
  # get the marketing version to be used as tag
  source release.spec.sh

  if [[ "${is_snapshot}" == true ]]; then
    tag_name="snapshot/${bundle_version}"
  else
    tag_name="${marketing_version}-${bundle_version}"
  fi
  echo "### Using ${tag_name} as tag name"
  git commit -am "Bump version to ${tag_name}"
  git tag -am "${tag_name}"
  git push
  git push origin "${tag_name}"

  echo "### Store release notes"
  echo "${release_notes}" > release-notes.temp.md

  echo "### Build VimR"

  # FOR DEV
  export create_gh_release=false
  export upload=false

  release_spec_file=release.spec.sh ./bin/build_release.sh

  if [[ "${create_gh_release}" == false ]]; then
    echo "### No github release, so exiting after building"
    exit 0
  fi

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

