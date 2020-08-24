from dataclasses import dataclass
from string import Template

from builder import Builder
from config import Config
from utils.shell import shell

# language=bash
download_command = Template(
    """
curl -L -s -o ag.tar.gz https://github.com/ggreer/the_silver_searcher/archive/${version}.tar.gz
rm -rf ag
tar xf ag.tar.gz
mv the_silver_searcher-${version} ag
"""
)

# language=bash
make_command = Template(
    """
pushd ag >/dev/null
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
copy_command = Template(
    """
cp -r "${target_specific_install_path}/include"/* "${install_include_path}"
cp -r "${target_specific_install_path}/lib"/* "${install_lib_path}"
"""
)


@dataclass(frozen=True)
class AgBuilder(Builder):
    deps: [Config]

    def make(self):
        include_flags = " ".join(
            [f'-I{c.x86_64_install_path.joinpath("include")}' for c in self.deps]
        )
        ldflags = " ".join([f'-L{c.install_path_lib}' for c in self.deps])
        cmd = self.make_command.substitute(
            dict(
                cflags=self.config.x86_64_full_cflags,
                ldflags=ldflags,
                include_flags=include_flags,
                deployment_target=self.config.x86_64_deployment_target,
                install_path=self.config.x86_64_install_path,
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)
