#!/bin/bash
set -Eeuo pipefail

echo "### Building deps"
pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

readonly deployment_target_file="./resources/macos_deployment_target.txt"
readonly deployment_target=$(cat ${deployment_target_file})
readonly gettext_version="0.20.1"

pushd NvimView > /dev/null
    rm -rf .deps
    mkdir .deps
    pushd .deps > /dev/null
        curl -o gettext.tar.xz https://ftp.gnu.org/gnu/gettext/gettext-${gettext_version}.tar.xz
        tar xf gettext.tar.xz
        mv gettext-${gettext_version} gettext

        pushd gettext > /dev/null
            # Configure from https://github.com/Homebrew/homebrew-core/blob/8d1ae1b8967a6b77cc1f6f1af6bb348b3268553e/Formula/gettext.rb
            # Set the deployment target to $deployment_target
            ./configure CFLAGS="-mmacosx-version-min=${deployment_target}" MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
                        --disable-dependency-tracking \
                        --disable-silent-rules \
                        --disable-debug \
                        --prefix=$(pwd)/../../third-party/libintl \
                        --with-included-gettext \
                        --with-included-glib \
                        --with-included-libcroco \
                        --with-included-libunistring \
                        --with-emacs \
                        --disable-java \
                        --disable-csharp \
                        --without-git \
                        --without-cvs \
                        --without-xz
            make
            echo "### libintl: ./NvimView/.deps/gettext/gettext-runtime/intl/.libs"
        popd > /dev/null
    popd > /dev/null

    echo "### Copy header/libs to third-party"
    mkdir -p third-party/libintl
    cp .deps/gettext/gettext-runtime/intl/libintl.h third-party/libintl/include/
    cp .deps/gettext/gettext-runtime/intl/.libs/libintl.a third-party/libintl/lib/
    cp .deps/gettext/gettext-runtime/intl/.libs/libintl.8.dylib third-party/libintl/lib/

    pushd third-party/libintl/lib
        ln -f -s libintl.8.dylib libintl.dylib
    popd > /dev/null
popd > /dev/null

popd > /dev/null
echo "### Built deps"
