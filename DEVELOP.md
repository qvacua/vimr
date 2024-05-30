## How to develop

VimR includes a stock Neovim. From Neovim `v0.10.0`, we provide pre-built universal Neovim,
see for instance <https://github.com/qvacua/vimr/releases/tag/neovim-v0.10.0-20240527.232810>.
In most cases, you can use the pre-built Neovim.
Run the following

```bash
clean=true for_dev=false ./bin/build_nvimserver.sh
```

to download and place the files in the appropriate places.
Now, you can just *run* VimR target in Xcode.

If you want to build Neovim locally, you can use

```bash
clean=true for_dev=true ./bin/build_nvimserver.sh
```

Afterwards, you can run VimR target in Xcode.

(This is used when generating source since we need some generated header files.)

### How to enable the Debug menu in Release build

```bash
defaults write com.qvacua.VimR enable-debug-menu 1
```

## How to release

### Neovim

* Update Neovim and generate sources:
    ```bash
    clean=true use_committed_nvim=true ./bin/generate_sources.sh
    ```
  Use `use_committed=false` if you want to use modified local Neovim submodule.
* Commit and push.
* Tag and push with the following
    ```bash
   version=neovim-vX.Y.Z-$(date "+%Y%m%d.%H%M%S"); git tag -a "${version}" -m "${version}"; git push origin "${version}"
    ```
* Github action will build universal binary + runtime and package it.
* Update the version of Neovim in `/bin/neovim/resources/buildInfo.json`

### VimR

* Set a new version of VimR via
    ```bash
    is_snapshot=true ./bin/set_new_versions.sh # for snapshot or
    is_snapshot=false marketing_version=0.38.3 ./bin/set_new_versions.sh # for release
    ```
  and commit. This will create a `${bundle_version}-snapshot/release.sh` file to be used
  with `build_release.sh` and `release-notes.temp.md` for release notes.
* Tag with the name
    - Snapshot: `snapshot/yyyymmdd.HHMMSS`
    - Release: `vX.Y.Z-yyyymmdd.HHMMSS`
* Push
* Add release notes to `release-notes.temp.md`.
* Build, package and upload via
    ```bash
    create_gh_release=true upload=true update_appcast=true \
    release_spec_file=....sh \
    ./bin/build_release.sh
    ```
* The `appcast{-snapshot}.xml` file is modified. Check and push.
