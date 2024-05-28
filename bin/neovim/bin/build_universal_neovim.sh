#!/bin/bash
set -Eeuo pipefail

# This script creates a universal build, incl. Treesitter `so`s. The Treesitter
# libs are put under the `runtime` folder instead of under `lib`.
#
# It expects to find the following files in the workspace root:
#   - nvim-macos-x86_64.tar.gz
#   - nvim-macos-arm64.tar.gz
# It will produce the following in the workspace root:
#   - nvim-macos-universal.tar.bz
#
# To be used in the context of Github actions

main() {
  # This script is located in /bin/neovim/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../../../" >/dev/null

  tar -xf nvim-macos-x86_64.tar.gz
  tar -xf nvim-macos-arm64.tar.gz

  mkdir -p "nvim-macos-universal"

  local universal_folder_path; universal_folder_path="$(pwd)/nvim-macos-universal";
  readonly universal_folder_path
  echo "${universal_folder_path}"
  ls -la

  mkdir -p "${universal_folder_path}/bin"
  cp -r nvim-macos-arm64/share "${universal_folder_path}"
  mkdir -p "${universal_folder_path}/share/nvim/runtime/parser"

  lipo -create nvim-macos-arm64/bin/nvim nvim-macos-x86_64/bin/nvim \
       -output "${universal_folder_path}/bin/nvim"
  for f in nvim-macos-arm64/lib/nvim/parser/*; do
    f="${f%/}"
    local filename="${f##*/}"
    lipo -create "nvim-macos-arm64/lib/nvim/parser/${filename}" \
                 "nvim-macos-x86_64/lib/nvim/parser/${filename}" \
         -output "${universal_folder_path}/share/nvim/runtime/parser/${filename}"
  done

  tar -cjf nvim-macos-universal.tar.bz nvim-macos-universal

  popd >/dev/null
}

main
