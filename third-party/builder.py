from dataclasses import dataclass
from string import Template

from config import Config
from utils.shell import shell


@dataclass(frozen=True)
class Builder:
    config: Config
    download_command: Template
    make_command: Template
    copy_command: Template

    def download(self):
        cmd = self.download_command.substitute(dict(version=self.config.version))
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)

    def make(self):
        cmd = self.make_command.substitute(
            dict(
                cflags=self.config.x86_64_full_cflags,
                deployment_target=self.config.x86_64_deployment_target,
                install_path=self.config.x86_64_install_path,
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)

    def copy_to_install_path(self):
        cmd = self.copy_command.substitute(
            dict(
                x86_64_install_path=self.config.x86_64_install_path,
                install_include_path=self.config.install_path_include,
                install_lib_path=self.config.install_path_lib,
            )
        )
        print(cmd)
        shell(cmd, cwd=self.config.working_directory)

    def build(self):
        self.config.clean_install_paths()
        self.config.ensure_paths_exist()

        self.download()
        self.make()
        self.copy_to_install_path()
