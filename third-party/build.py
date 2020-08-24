import argparse
import pathlib
import shutil

from builder import Builder
from config import Config
from deps import ag, pcre, xz
from deps.ag import AgBuilder

DEPS_FILE_NAME = ".deps"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--xz-version", action="store", dest="xz_version", type=str, required=True,
    )

    parser.add_argument(
        "--pcre-version", action="store", dest="pcre_version", type=str, required=True,
    )

    parser.add_argument(
        "--ag-version", action="store", dest="ag_version", type=str, required=True,
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

    cwd = pathlib.Path(__file__).parent.resolve()
    install_path = cwd
    install_path_lib = install_path.joinpath("lib")
    install_path_include= install_path.joinpath("include")

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
    builders = {
        "xz": Builder(
            xz_config,
            download_command=xz.download_command,
            make_command=xz.make_command,
            copy_command=xz.copy_command,
        ),
        "pcre": Builder(
            pcre_config,
            download_command=pcre.download_command,
            make_command=pcre.make_command,
            copy_command=pcre.copy_command,
        ),
        "ag": AgBuilder(
            Config(
                version=args.ag_version,
                arm64_deployment_target=arm64_deployment_target,
                x86_64_deployment_target=x86_64_deployment_target,
                default_cflags="-g -O2 -D_THREAD_SAFE -pthread",
                target_install_path_parent=cwd.joinpath("libag"),
                install_path_lib=install_path_lib,
                install_path_include=install_path_include,
                working_directory=cwd.joinpath(DEPS_FILE_NAME),
            ),
            download_command=ag.download_command,
            make_command=ag.make_command,
            copy_command=ag.copy_command,
            deps=[xz_config, pcre_config],
        ),
    }

    shutil.rmtree(install_path_lib, ignore_errors=True)
    shutil.rmtree(install_path.joinpath("include"), ignore_errors=True)

    builders["xz"].build()
    builders["pcre"].build()
    builders["ag"].build()
