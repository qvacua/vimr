nvox
====

<strong>N</strong>eo<strong>V</strong>im for <strong>O</strong>S <strong>X</strong>

## About

nvox is a *toy* project, meaning e.g. no tests whatsoever, for me to:

- play around with [NeoVim](https://github.com/neovim),
- play around with the `XPC`-architecture and to find out whether this is a viable choice for an OSX-NeoVim-GUI-app and
- play around with Swift (and [RxSwift](https://github.com/ReactiveX/RxSwift)).

It could very well be that nothing useful comes out of it.

## How to Build

First install `homebrew`, then:

```bash
xcode-select --install # install the Xcode command line tools
brew install carthage # install Carthage for dependency management
brew install libtool automake cmake pkg-config gettext ninja # install libs and tools for neovim

carthage update --platform osx

git submodule update --init
cd neovim
ln -s ../NeoVimXpc/local.mk .
make libnvim # optional, the nvox target in Xcode also does this
```

Run the `nvox`-target in Xcode.

## Project Setup

* The library `libiconv` is linked by the linker flag `-liconv`. The version bundled with OSX will be linked.
* The library `libintl` should be installed by `homebrew` and is statically linked by explicitly using the linker flag `/usr/local/opt/gettext/lib/libintl.a`.
* Other libraries used by NeoVim, which are automatically built by building `libnvim`, are linked by adding them to the Xcode project.
