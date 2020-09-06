from string import Template
from config import Target
from builder import Builder
from utils.shell import shell


# language=bash
download_command = Template(
    """
curl -L -s -o pcre.tar.bz2 "https://ftp.pcre.org/pub/pcre/pcre-${version}.tar.bz2"
"""
)

# language=bash
extract_command = Template(
    """
rm -rf "pcre-${target}"
tar xf pcre.tar.bz2
mv "pcre-${version}" "pcre-${target}"
"""
)

# language=bash
make_command = Template(
    """
pushd pcre-${target} >/dev/null
./configure \
    CFLAGS="${cflags}" \
    CXXFLAGS="${cflags}" \
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
    --host="${host}" \
    --prefix="${install_path}"
make MACOSX_DEPLOYMENT_TARGET="${deployment_target}" install
popd >/dev/null
"""
)

# language=bash
build_universal_and_install_command = Template(
    """
lipo -create -output "${install_lib_path}/libpcre.a" "${arm64_lib_path}/libpcre.a" "${x86_64_lib_path}/libpcre.a"
cp -r "${arm64_include_path}"/* "${install_include_path}"
"""
)


class PcreBuilder(Builder):
    def make(self, target: Target):
        cmd = self.make_command.substitute(
            dict(
                target=target.value,
                cflags=self.config.target_specific_full_cflags(target),
                deployment_target=self.config.target_specific_deployment_target(target),
                install_path=self.config.target_specific_install_path(target),
                host=self.config.target_specific_host(target),
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)
