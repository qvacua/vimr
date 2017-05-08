#!/bin/bash

set -e

echo "### Building libnvim"

# We assume that we're already in the neovim project root
make CFLAGS='-mmacosx-version-min=10.10' MACOSX_DEPLOYMENT_TARGET=10.10 CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM" libnvim

echo "### Built libnvim"
