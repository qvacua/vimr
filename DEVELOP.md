## How to develop

### No change in NvimServer

If you did not change NvimServer, i.e. NvimServer, NvimServerTypes, and neovim,
then, do the following to run VimR:

* `./bin/download_nvimserver.sh`
* Run VimR scheme in Xcode

A development version of VimR will be built and run,
i.e. the bundle identifier will be `com.qvacua.VimR.dev` and the name of the app will be `VimR-dev`.
If you want to build a development version as a release build, then use the following:

```bash
clean=true ./bin/build_vimr_dev.sh
```

### Changes in NvimServer

Since SwiftPM does not support a script phase, we have to copy some files manually,
e.g. `NvimServer` binary.
This can be done with the following:

```bash
build_libnvim=true clean=true ./bin/build_nvimserver_for_local_dev.sh
```

See the `build_nvimserver_for_local_dev` script for default values of the env vars.
You can also use a watch script as follows (it uses `entr`):

```bash
clean_initial_build=true ./bin/watch_nvimserver_and_build
```

When `clean_initial_build` is `true`, the script will clean and build,
then continuously invoke the `build_nvimserver_for_local_dev` script.

## How to release

### NvimServer

* Tag with the name `nvimserver-x.y.z-n`. GitHub actions will build the `x86_64` version,
  create a release and upload it.
* Build the `arm64` version locally and upload it:
  ```bash
  clean=true build_libnvim=true ./NvimServer/bin/build_nvimserver.sh
  ```
* Build a universal binary by the following and upload the artefact:
  ```bash
  tag=nvimserver-x.y.z-n ./NvimServer/bin/build_release.sh
  ```

### VimR

* Set a new version of VimR via
    ```bash
    is_snapshot=true ./bin/set_new_versions.sh # for snapshot or
    is_snapshot=false marketing_version=0.38.3 ./bin/set_new_versions.sh # for release
    ```
  and commit. This will create a `${bundle_version}-snapshot/release.sh` file to be used
  with `build_release.sh`.
* Tag with the name
    - Snapshot: `snapshot/yyyymmdd.HHMMSS`
    - Release: `vX.Y.Z-yyyymmdd.HHMMSS`
* Push
* Build, package and upload via
    ```bash
    create_gh_release=true upload=true update_appcast=true \
    release_spec_file=....sh \
    ./bin/build_release.sh
    ```
* The `appcast{-snapshot}.xml` file is modified. Check and push.

