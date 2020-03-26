#!/bin/bash
set -Eeuo pipefail

echo "### Building libnvim"
pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

readonly deployment_target_file="./resources/macos_deployment_target.txt"
readonly deployment_target=$(cat ${deployment_target_file})

# Brew's gettext does not get sym-linked to PATH
export PATH=/usr/local/opt/gettext/bin:$PATH

pushd NvimView/neovim
    ln -sf ../local.mk .

    # Use custom gettext source only when building libnvim => not in local.mk which is also used to build the full nvim
    # to get the full runtime.
    make \
        SDKROOT=$(xcrun --show-sdk-path) \
        CFLAGS="-mmacosx-version-min=${deployment_target}" \
        CXXFLAGS="-mmacosx-version-min=${deployment_target}" \
        MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
        CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
        DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
        libnvim
popd > /dev/null

popd > /dev/null
echo "### Built libnvim"
