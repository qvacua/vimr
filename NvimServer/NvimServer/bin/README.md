## How to develop

First, clean everything

```
$ ./bin/clean_all.sh
```

Then, build `libnvim` once with dependencies

```
$ target=x86_64 build_deps=true ./bin/build_libnvim.sh
```

After editing the code of neovim or NvimServer, you build NvimServer in Xcode or by executing
the following:

```
$ target="${ARCH}" build_deps=false build_dir="${PROJECT_ROOT}/NvimServer/build" \
  ./bin/build_nvimserver.sh
```

where `${ARCH}` is either `arm64` or `x86_64`.
We use `${PROJECT_ROOT}/NvimServer/build` as the NvimServer target assumes that location.

## How to release

```
$ ./bin/build_release.sh 
```

The resulting package will be in `${PROJECT_ROOT}/NvimServer/build/NvimServer.tar.bz2`.

## Individual steps

In the following the `target` variable can be either `x86_64` or `arm64`.

### How to build `libintl`

```
$ ./bin/build_deps.sh
```

which will result in

```
${PROJECT_ROOT}
    NvimServer
        third-party
            lib
                liba
                libb
                ...
            include
                a.h
                b.h
                ...
            x86_64
                lib
                    liba
                    libb
                include
                    a.h
                    b.h
```

Files, e.g. `lib` and `include`, in `${PROJECT_ROOT}/NvimServer/third-party` are used to build
`libnvim` and NvimServer.

### How to build `libnvim`

```
$ build_deps=true ./bin/build_libnvim.sh
```

When `build_deps` is `true`, then the `build_deps.sh` is executed. The resuling library will be
located in `/build/lib/libnvim.a`.

### how to build NvimServer

```
$ build_dir="${some_dir}" build_libnvim=true build_deps=true ./bin/build_nvimserver.sh
```

The `build_libnvim.sh` script is executed automatically with the given parameters. The resulting
binary will be located in `${some_dir}`.
