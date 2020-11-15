from string import Template

# language=bash
download_command = Template(
    """
curl -L -s -o xz.tar.gz "https://tukaani.org/xz/xz-${version}.tar.gz"
"""
)

# language=bash
extract_command = Template(
    """
rm -rf "xz-${target}"
tar xf xz.tar.gz
mv "xz-${version}" "xz-${target}"
"""
)

# language=bash
make_command = Template(
    """
pushd ./xz-${target} >/dev/null
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
    --host="${host}" \
    --prefix="${install_path}"
make MACOSX_DEPLOYMENT_TARGET="${deployment_target}" install
popd >/dev/null
"""
)

# language=bash
build_universal_and_install_command = Template(
    """
lipo -create -output "${install_lib_path}/liblzma.a" "${arm64_lib_path}/liblzma.a" "${x86_64_lib_path}/liblzma.a"
cp -r "${arm64_include_path}"/* "${install_include_path}"
"""
)
