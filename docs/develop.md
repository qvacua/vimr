## How to develop

### No change in NvimServer

If you did not change code in NvimServer, i.e. NvimServer, NvimServerTypes, and neovim,
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
build_libnvim=true clean=true download_gettext=true ./bin/build_nvimserver_for_local_dev.sh
```

Set `download_gettext` to true when you are building NvimServer locally for the first time.
See the `build_nvimserver_for_local_dev` script for default values of the env vars.
You can also use a watch script as follows:

```bash
clean_initial_build=true ./bin/watch_nvimserver_and_build
```

When `clean_initial_build` is `true`, the script will download `gettext`, clean, and build,
then continuously invoke the `build_nvimserver_for_local_dev` script.

## How to release

* Tag NvimServer: Travis will create a Github release, build,
  and upload `gettext` and `NvimServer` for `x86_64`.
* Build `gettext` and `NvimServer` on an `arm64` Mac
  and upload them to the release from the last step.
* Set a new version of VimR via
    ```
    ./bin/set_new_version.sh`
    ```
* Push and and build using
    ```
    code_sign=true use_carthage_cache=false ./bin/build_vimr.sh 
    ```
* Notarize using
    ```
    vimr_app_path=./build/Build/Products/Release/VimR.app ./bin/notarize_vimr.sh
    ```
* Create a Github release, add release notes, and upload VimR archived by
    ```
    cd ./build/Build/Products/Release
    tar cjf VimR-SNAPSHOT-20201210.181940.tar.bz2 VimR.app
    ```
* Update `appcast` file, e.g.
    ```
    cd ./build/Build/Products/Release
    ./bin/set_appcast.py "${vimr_file}" "${bundle_version}" "${marketing_version}" "${tag}" "${is_snapshot}" 
    cp appcast_snapshot.xml "${project_root}"
    ```

*TODO*: Automate this again.
