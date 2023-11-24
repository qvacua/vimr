#!/bin/bash
set -Eeuo pipefail

readonly version="5.0.0"
readonly url="https://github.com/sindresorhus/github-markdown-css/archive/refs/tags/v${version}.tar.gz"
readonly ref_md5="91db7943196075d6790c76fa184591d0"

main() {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  local existing_md5; existing_md5="$(md5 -q ./VimR/VimR/markdown/github-markdown.css || echo "no file")"; readonly existing_md5
  if [[ "${existing_md5}" == "${ref_md5}" ]]; then
    echo "### CSS already exists, exiting"
    popd >/dev/null
    exit 0
  fi

  echo "### Downloading CSS and copying"
  local temp_dir; temp_dir="$(mktemp -d)"; readonly temp_dir
  echo "${temp_dir}"

  pushd "${temp_dir}" >/dev/null
    curl -s -L "${url}" -o "css.tar.gz"
    tar -xf css.tar.gz
  popd >/dev/null

  cp "${temp_dir}/github-markdown-css-${version}/github-markdown.css" ./VimR/VimR/markdown

  popd >/dev/null
}

main

