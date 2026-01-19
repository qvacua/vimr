#!/bin/bash
set -Eeuo pipefail

# Use environment variable 'clean' if set, otherwise default to false
clean=${clean:-false}

main() {
  local -r script_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
  )
  local -r project_root="${script_path}/.."
  local -r build_products_path="${project_root}/build/Build/Products/Release"
  local -r app_name="VimR.app"
  local -r source_app="${build_products_path}/${app_name}"
  local -r target_app="/Applications/${app_name}"

  pushd "${project_root}" >/dev/null

  echo "### Building local release (clean=${clean})..."

  # Call the main build script with appropriate flags
  # clean: user provided (default false)
  # notarize: false (local dev)
  # trust_plugins: true (skip validation)
  # strip_symbols: false (optional, but faster for dev)
  clean=${clean} notarize=false trust_plugins=true strip_symbols=false ./bin/build_vimr.sh

  if [[ ! -d "${source_app}" ]]; then
    echo "### Error: Built app not found at ${source_app}"
    exit 1
  fi

  echo "### Installing to ${target_app}..."

  # Gracefully quit running instance
  if pgrep -f "VimR" >/dev/null; then
    echo "### Quitting running VimR..."
    osascript -e 'quit app "VimR"' || true
    # Wait a moment for it to close, or force kill if stuck
    sleep 1
    pkill -f "VimR" || true
  fi

  # Need sudo for /Applications
  echo "### You may be asked for sudo password to overwrite /Applications/VimR.app"

  if [[ -d "${target_app}" ]]; then
    sudo rm -rf "${target_app}"
  fi

  sudo cp -R "${source_app}" "${target_app}"

  echo "### Successfully installed VimR to /Applications"
  popd >/dev/null
}

main
