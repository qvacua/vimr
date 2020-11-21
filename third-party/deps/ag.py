from dataclasses import dataclass
from string import Template

from builder import Builder
from config import Config, Target
from utils.shell import shell

# language=bash
download_command = Template(
    """
curl -L -s -o ag.tar.gz https://github.com/ggreer/the_silver_searcher/archive/${version}.tar.gz
"""
)

# language=bash
extract_command = Template(
    """
rm -rf "ag-${target}"
tar xf ag.tar.gz
mv "the_silver_searcher-${version}" "ag-${target}"
"""
)

# language=bash
make_command = Template(
    """
pushd ag-${target} >/dev/null
  ./autogen.sh
  ./configure
      CFLAGS="${cflags} ${include_flags}" \
      LDFLAGS="${ldflags}" \
      MACOSX_DEPLOYMENT_TARGET="${deployment_target}"

  pushd src > /dev/null
    cc ${cflags} ${include_flags} -c ignore.c log.c options.c print.c scandir.c search.c lang.c util.c decompress.c zfile.c
    ar -crs libag.a ignore.o log.o options.o print.o scandir.o search.o lang.o util.o decompress.o zfile.o
    mkdir -p "${install_path}/lib"
    mv libag.a "${install_path}/lib"

    mkdir -p "${install_path}/include"
    cp *.h "${install_path}/include"
  popd >/dev/null
popd >/dev/null
"""
)

# language=bash
build_universal_and_install_command = Template(
    """
lipo -create -output "${install_lib_path}/libag.a" "${arm64_lib_path}/libag.a" "${x86_64_lib_path}/libag.a"
cp -r "${arm64_include_path}"/* "${install_include_path}"
"""
)


@dataclass(frozen=True)
class AgBuilder(Builder):
    deps: [Config]

    def make(self, target: Target):
        include_flags = f"-I{self.config.install_path_include}"
        ldflags = f"-L{self.config.install_path_lib}"
        cmd = self.make_command.substitute(
            dict(
                target=target.value,
                cflags=self.config.target_specific_full_cflags(target),
                ldflags=ldflags,
                include_flags=include_flags,
                deployment_target=self.config.target_specific_deployment_target(target),
                install_path=self.config.target_specific_install_path(target),
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)
