## How to develop

To build NvimServer, do the following

```bash
clean=false ./bin/build_neovim_for_local_dev.sh
```

You can set `clean=true` if you want to clean the existing build.

## How to build nightly

```bash
git tag -f neovim-nightly; git push -f origin neovim-nightly
```

Then, GitHub actions will build and re-create the release.

## How to release

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

