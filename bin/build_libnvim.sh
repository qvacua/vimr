#!/bin/bash

set -e

echo "### Building libnvim"

# Brew's gettext does not get sym-linked to PATH
export PATH=/usr/local/opt/gettext/bin:$PATH

ln -sf ../local.mk .

# We assume that we're already in the neovim project root.
# Use custom gettext source only when building libnvim => not in local.mk which is also used to build the full nvim
# to get the full runtime.
make CFLAGS='-mmacosx-version-min=10.10' \
     MACOSX_DEPLOYMENT_TARGET=10.10 \
     CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM" \
     libnvim

echo "### Built libnvim"
