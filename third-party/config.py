import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Config:
    """The working_directory should be set for the particular library, e.g. ./.deps/xz"""

    version: str

    arm64_deployment_target: str
    x86_64_deployment_target: str

    default_cflags: str

    target_install_path_parent: Path
    install_path_include: Path
    install_path_lib: Path
    working_directory: Path

    @property
    def arm64_full_cflags(self) -> str:
        return f"{self.default_cflags} --target=arm64-apple-macos{self.arm64_deployment_target}"

    @property
    def x86_64_full_cflags(self) -> str:
        return f"{self.default_cflags} --target=x86_64-apple-macos{self.x86_64_deployment_target}"

    @property
    def arm64_install_path(self) -> Path:
        return self.target_install_path_parent.joinpath("arm64")

    @property
    def x86_64_install_path(self) -> Path:
        return self.target_install_path_parent.joinpath("x86_64")

    def clean_install_paths(self):
        shutil.rmtree(self.arm64_install_path, ignore_errors=True)
        shutil.rmtree(self.x86_64_install_path, ignore_errors=True)
        shutil.rmtree(self.target_install_path_parent, ignore_errors=True)

    def ensure_paths_exist(self):
        self.target_install_path_parent.mkdir(parents=True, exist_ok=True)
        self.install_path_lib.mkdir(parents=True, exist_ok=True)
        self.install_path_include.mkdir(parents=True, exist_ok=True)

        self.arm64_install_path.mkdir(parents=True, exist_ok=True)
        self.x86_64_install_path.mkdir(parents=True, exist_ok=True)

        self.working_directory.mkdir(parents=True, exist_ok=True)
