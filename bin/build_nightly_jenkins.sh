#!/bin/bash
set -Eeuo pipefail

readonly branch=${branch:?"which branch to use"}

upload_artifact() {
  local -r vimr_artifact_path="$1"
  local -x GH_TOKEN
  GH_TOKEN=$(cat ~/.local/secrets/github.qvacua.release.token)
  readonly GH_TOKEN

  echo "### Uploading artifact"
  gh release upload "neovim-nightly" "${vimr_artifact_path}"
  echo "### Uploaded artifact"
}

main() {
  echo "### Releasing nightly VimR started"

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  git submodule update --init
  git tag -f neovim-nightly; git push -f origin neovim-nightly

  echo "### Build VimR"
  clean=true notarize=true ./bin/build_vimr.sh

  pushd ./build/Build/Products/Release >/dev/null
    tar cjf "VimR-nightly.tar.bz2" VimR.app
    upload_artifact "VimR-nightly.tar.bz2"
  popd >/dev/null

  popd >/dev/null

  echo "### Releasing nightly VimR ended"
}

main


