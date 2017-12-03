#!/bin/bash

set -e

GETTEXT_VERSION="0.19.8.1"

echo "### Building deps"

pushd NvimView

rm -rf .deps
mkdir .deps
pushd .deps

curl -o gettext.tar.xz https://ftp.gnu.org/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz
tar xf gettext.tar.xz
mv gettext-${GETTEXT_VERSION} gettext

pushd gettext
# Configure from https://github.com/Homebrew/homebrew-core/blob/8d1ae1b8967a6b77cc1f6f1af6bb348b3268553e/Formula/gettext.rb
# Set the deployment target to 10.10
./configure CFLAGS='-mmacosx-version-min=10.10' MACOSX_DEPLOYMENT_TARGET=10.10 \
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
echo "### libintl: \$PROJECT_ROOT/.deps/gettext/gettext-runtime/intl/.libs"
popd # .deps

popd # $PROJECT_ROOT

echo "### Copy header/libs to third-party"
mkdir -p third-party/libintl
cp .deps/gettext/gettext-runtime/intl/libintl.h third-party/libintl/include/
cp .deps/gettext/gettext-runtime/intl/.libs/libintl.a third-party/libintl/lib/
cp .deps/gettext/gettext-runtime/intl/.libs/libintl.8.dylib third-party/libintl/lib/

pushd third-party/libintl/lib
ln -f -s libintl.8.dylib libintl.dylib
popd

popd # $WORKSPACE_ROOT

echo "### Built deps"
