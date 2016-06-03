nvox
====

## About

nvox is a *toy* project, meaning e.g. no tests whatsoever, for me to:

- play around with [NeoVim](https://github.com/neovim),
- play around with the `XPC`-architecture and to find out whether this is a viable choice for an OSX-NeoVim-GUI-app and
- play around with Swift.

It could very well be that nothing useful comes out of it.

## How to Build

```bash
brew install gettext
git submodule update --init
cd neovim
ln -s ../NeoVimXpc/local.mk .
make libnvim # optional, the nvox target in Xcode also does this
```

Then run the `nvox`-target in Xcode.

## Project Setup

* The library `libiconv` is linked by the linker flag `-liconv`. The version bundled with OSX will be linked.
* The library `libintl` should be installed by `homebrew` and is statically linked by explicitly using the linker flag `/usr/local/opt/gettext/lib/libintl.a`.
* Other libraries used by NeoVim, which are automatically built by building `libnvim`, are linked by adding them to the Xcode project.
