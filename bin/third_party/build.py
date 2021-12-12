import argparse
import pathlib
import shutil

from third_party.config import Config
from third_party.deps import ag, pcre, xz
from third_party.deps.ag import AgBuilder
from third_party.builder import Builder

DEPS_FILE_NAME = ".deps"
PACKAGE_NAME = "vimr-deps"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--xz-version",
        action="store",
        dest="xz_version",
        type=str,
        required=True,
    )

    parser.add_argument(
        "--pcre-version",
        action="store",
        dest="pcre_version",
        type=str,
        required=True,
    )

    parser.add_argument(
        "--ag-version",
        action="store",
        dest="ag_version",
        type=str,
        required=True,
    )

    parser.add_argument(
        "--arm64-deployment-target",
        action="store",
        dest="arm64_deployment_target",
        type=str,
        required=True,
    )
    parser.add_argument(
        "--x86_64-deployment-target",
        action="store",
        dest="x86_64_deployment_target",
        type=str,
        required=False,
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    arm64_deployment_target = args.arm64_deployment_target
    x86_64_deployment_target = args.x86_64_deployment_target

    cwd = pathlib.Path(__file__).parent.resolve().joinpath("build")
    shutil.rmtree(cwd, ignore_errors=True)
    cwd.mkdir(parents=True, exist_ok=True)

    install_path = cwd.parent.joinpath(PACKAGE_NAME)
    shutil.rmtree(install_path, ignore_errors=True)
    install_path_lib = install_path.joinpath("lib")
    install_path_include = install_path.joinpath("include")

    xz_config = Config(
        version=args.xz_version,
        arm64_deployment_target=arm64_deployment_target,
        x86_64_deployment_target=x86_64_deployment_target,
        default_cflags="-g -O2",
        target_install_path_parent=cwd.joinpath("libxz"),
        install_path_lib=install_path_lib,
        install_path_include=install_path_include,
        working_directory=cwd.joinpath(DEPS_FILE_NAME),
    )
    pcre_config = Config(
        version=args.pcre_version,
        arm64_deployment_target=arm64_deployment_target,
        x86_64_deployment_target=x86_64_deployment_target,
        default_cflags="-D_THREAD_SAFE -pthread -g -O2",
        target_install_path_parent=cwd.joinpath("libpcre"),
        install_path_lib=install_path_lib,
        install_path_include=install_path_include,
        working_directory=cwd.joinpath(DEPS_FILE_NAME),
    )
    ag_config = Config(
        version=args.ag_version,
        arm64_deployment_target=arm64_deployment_target,
        x86_64_deployment_target=x86_64_deployment_target,
        default_cflags="-g -O2 -D_THREAD_SAFE -pthread",
        target_install_path_parent=cwd.joinpath("libag"),
        install_path_lib=install_path_lib,
        install_path_include=install_path_include,
        working_directory=cwd.joinpath(DEPS_FILE_NAME),
    )
    builders = {
        "xz": Builder(
            xz_config,
            download_command=xz.download_command,
            extract_command=xz.extract_command,
            make_command=xz.make_command,
            build_universal_and_install_command=xz.build_universal_and_install_command,
        ),
        "pcre": Builder(
            pcre_config,
            download_command=pcre.download_command,
            make_command=pcre.make_command,
            extract_command=pcre.extract_command,
            build_universal_and_install_command=pcre.build_universal_and_install_command,
        ),
        "ag": AgBuilder(
            ag_config,
            download_command=ag.download_command,
            make_command=ag.make_command,
            deps=[xz_config, pcre_config],
            extract_command=ag.extract_command,
            build_universal_and_install_command=ag.build_universal_and_install_command,
        ),
    }

    builders["xz"].build()
    builders["pcre"].build()
    builders["ag"].build()
