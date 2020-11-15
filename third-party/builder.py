from dataclasses import dataclass
from string import Template

from config import Config, Target
from utils.shell import shell


@dataclass(frozen=True)
class Builder:
    config: Config

    download_command: Template
    extract_command: Template
    make_command: Template
    build_universal_and_install_command: Template

    def download(self):
        cmd = self.download_command.substitute(dict(version=self.config.version))
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)

    def extract(self, target: Target):
        cmd = self.extract_command.substitute(
            dict(
                target=target.value,
                version=self.config.version,
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)

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

    def build_universal_and_install(self):
        cmd = self.build_universal_and_install_command.substitute(
            dict(
                install_lib_path=self.config.install_path_lib,
                install_include_path=self.config.install_path_include,
                arm64_lib_path=self.config.target_specific_install_path(Target.arm64).joinpath(
                    "lib"
                ),
                arm64_include_path=self.config.target_specific_install_path(Target.arm64).joinpath(
                    "include"
                ),
                x86_64_lib_path=self.config.target_specific_install_path(Target.x86_64).joinpath(
                    "lib"
                ),
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)

    def build(self):
        self.config.clean_install_paths()
        self.config.ensure_paths_exist()

        self.download()

        self.extract(Target.arm64)
        self.make(Target.arm64)

        self.extract(Target.x86_64)
        self.make(Target.x86_64)

        self.build_universal_and_install()
