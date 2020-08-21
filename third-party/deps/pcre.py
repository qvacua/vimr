from string import Template


# language=bash
download_command = Template(
    """
curl -L -s -o pcre.tar.bz2 "https://ftp.pcre.org/pub/pcre/pcre-${version}.tar.bz2"
rm -rf pcre
tar xf pcre.tar.bz2
mv "pcre-${version}" pcre
"""
)

# language=bash
make_command = Template(
    """
pushd pcre >/dev/null
./configure \
    CFLAGS="${cflags}" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    --disable-dependency-tracking \
    --enable-utf8 \
    --enable-pcre8 \
    --enable-pcre16 \
    --enable-pcre32 \
    --enable-unicode-properties \
    --enable-pcregrep-libz \
    --enable-pcregrep-libbz2 \
    --enable-jit \
    --disable-shared \
    --prefix="${install_path}"
make MACOSX_DEPLOYMENT_TARGET="${deployment_target}" install
popd >/dev/null
"""
)

# language=bash
copy_command = Template(
    """
cp -r "${x86_64_install_path}/include"/* "${install_include_path}"
cp -r "${x86_64_install_path}/lib"/* "${install_lib_path}"
"""
)
