#!/bin/bash
set -Eeuo pipefail

echo "### Building deps"
pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

readonly deployment_target_file="./resources/macos_deployment_target.txt"
readonly deployment_target=$(cat ${deployment_target_file})
readonly gettext_version="0.20.1"
readonly pcre_version="8.43"
readonly xz_version="5.2.4"
readonly ag_version="2.2.0"

readonly build_ag=${build_ag:-false}
readonly build_pcre=${build_pcre:-false}
readonly build_xz=${build_xz:-false}
readonly build_gettext=${build_gettext:-false}

build_ag () {
pushd .deps > /dev/null
    curl -L -o ag.tar.gz https://github.com/ggreer/the_silver_searcher/archive/${ag_version}.tar.gz
    tar xf ag.tar.gz
    mv the_silver_searcher-${ag_version} ag

    pushd ag > /dev/null
        ./autogen.sh

        xz_include=$(pwd)/../../third-party/libxz/include
        pcre_include=$(pwd)/../../third-party/libpcre/include
        ./configure CFLAGS="-mmacosx-version-min=${deployment_target} -I${xz_include} -I${pcre_include}" \
                    LDFLAGS="-L$(pwd)/../../third-party/libxz/lib -L$(pwd)/../../third-party/libpcre/lib" \
                    MACOSX_DEPLOYMENT_TARGET=${deployment_target}
        pushd src > /dev/null
            cc -c ignore.c log.c options.c print.c scandir.c search.c lang.c util.c decompress.c zfile.c
            ar -crs libag.a ignore.o log.o options.o print.o scandir.o search.o lang.o util.o decompress.o zfile.o
            mkdir -p $(pwd)/../../../third-party/libag/lib
            mv libag.a $(pwd)/../../../third-party/libag/lib

            mkdir -p $(pwd)/../../../third-party/libag/include
            cp *.h $(pwd)/../../../third-party/libag/include
        popd > /dev/null
    popd > /dev/null
popd > /dev/null
}

build_xz () {
pushd .deps > /dev/null
    curl -L -o xz.tar.gz https://tukaani.org/xz/xz-${xz_version}.tar.gz
    tar xf xz.tar.gz
    mv xz-${xz_version} xz

    pushd xz > /dev/null
        # configure from https://github.com/Homebrew/homebrew-core/blob/c9882801013d6bc5202b91ef56ff5838d18bbab2/Formula/xz.rb
        ./configure CFLAGS="-mmacosx-version-min=${deployment_target}" MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
                    --disable-debug \
                    --disable-dependency-tracking \
                    --disable-silent-rules \
                    --prefix=$(pwd)/../../third-party/libxz
        make
        make install
        rm -rf $(pwd)/../../third-party/libxz/bin
        rm -rf $(pwd)/../../third-party/libxz/share
    popd > /dev/null
popd > /dev/null
}

build_pcre () {
pushd .deps > /dev/null
    curl -L -o pcre.tar.bz2 https://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.bz2
    tar xf pcre.tar.bz2
    mv pcre-${pcre_version} pcre

    pushd pcre > /dev/null
        # configure from https://github.com/Homebrew/homebrew-core/blob/c9882801013d6bc5202b91ef56ff5838d18bbab2/Formula/pcre.rb
        ./configure CFLAGS="-mmacosx-version-min=${deployment_target}" MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
                    --disable-dependency-tracking \
                    --prefix=$(pwd)/../../third-party/libpcre \
                    --enable-utf8 \
                    --enable-pcre8 \
                    --enable-pcre16 \
                    --enable-pcre32 \
                    --enable-unicode-properties \
                    --enable-pcregrep-libz \
                    --enable-pcregrep-libbz2 \
                    --enable-jit
        make
        make install
        rm -rf $(pwd)/../../third-party/libpcre/bin
        rm -rf $(pwd)/../../third-party/libpcre/share
    popd > /dev/null
popd > /dev/null
}

build_vimr_deps () {
rm -rf .deps
mkdir .deps

if [[ ${build_pcre} == true ]] ; then
    rm -rf third-party/libpcre
    rm -rf third-party/libag

    build_pcre
    build_ag
fi

if [[ ${build_xz} == true ]] ; then
    rm -rf third-party/libxz
    build_xz
fi

if [[ ${build_ag} == true ]] ; then
    rm -rf third-party/libag
    build_ag
fi
}

build_gettext () {
pushd NvimView > /dev/null
    mkdir -p third-party/libintl
    rm -rf .deps
    mkdir .deps
    pushd .deps > /dev/null
        curl -L -o gettext.tar.xz https://ftp.gnu.org/gnu/gettext/gettext-${gettext_version}.tar.xz
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
}

if [[ ${build_gettext} == true ]] ; then
    build_gettext
fi

build_vimr_deps
