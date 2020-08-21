from string import Template

# language=bash
download_command = Template(
    """
curl -L -s -o xz.tar.gz "https://tukaani.org/xz/xz-${version}.tar.gz"
rm -rf xz
tar xf xz.tar.gz
mv "xz-${version}" xz
"""
)

# language=bash
make_command = Template(
    """
pushd ./xz >/dev/null
./configure \
    CFLAGS="${cflags}" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --disable-shared \
    --disable-xz \
    --disable-xzdec \
    --disable-lzmadec \
    --disable-lzmainfo \
    --disable-lzma-links \
    --disable-scripts \
    --disable-doc \
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