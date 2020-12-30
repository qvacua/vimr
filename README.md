# VimR — Neovim GUI for macOS

[Download](https://github.com/qvacua/vimr/releases) • [Documentation](https://github.com/qvacua/vimr/wiki)

![Screenshot 1](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot1.png)
![Screenshot 2](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot2.png)

## About

Project VimR is a Neovim GUI for macOS.
The goal is to build an editor that uses Neovim inside with many of the convenience
GUI features similar to those present in modern editors. We mainly use Swift,
but also use C/Objective-C when where appropriate.

There are other Neovim GUIs for macOS, e.g. [NyaoVim](https://github.com/rhysd/NyaoVim), [neovim-dot-app](https://github.com/rogual/neovim-dot-app), [Oni](https://www.onivim.io), etc., so why?

- Play around with [Neovim](https://github.com/qvacua/neovim),
- play around with Swift (and especially with [RxSwift](https://github.com/ReactiveX/RxSwift)), and
- (most importantly) have fun!

If you want to support VimR financially, use [Github's Sponsor](https://github.com/sponsors/qvacua)
or [Bountysource](https://www.bountysource.com/teams/vimr).

## Download

Pre-built binaries can be found under [Releases](https://github.com/qvacua/vimr/releases).

## Reusable Components

* [RxMessagePort](https://github.com/qvacua/vimr/blob/develop/RxPack/RxMessagePort.swift): RxSwift wrapper for local and remote `CFMessagePort`.
* [RxMsgpackRpc](https://github.com/qvacua/vimr/blob/develop/RxPack/RxMsgpackRpc.swift): Implementation of MsgpackRpc using RxSwift.
* [RxNeovimApi](https://github.com/qvacua/vimr/blob/develop/RxPack/RxNeovimApi.swift): RxSwift wrapper of Neovim API.
* [NvimView](https://github.com/qvacua/vimr/tree/develop/NvimView): SwiftPM module which bundles everything, e.g. Neovim's `runtime`-files, needed to embed Neovim in a Cocoa App.

## Some Features

* Markdown preview
* Generic HTML preview (retains the scroll position when reloading)
* Fuzzy file finder a la Xcode's "Open Quickly..."
* Trackpad support: Pinching for zooming and two-finger scrolling.
* Ligatures: Turned off by default. Turn it on in the Preferences.
* Command line tool.
* (Simple) File browser
* Flexible workspace model a la JetBrain's IDEs

## How to Build

First after cloning the VimR source tree you need to initialize git submodules

```bash
git lfs install
git submodule update --init
```

First install `homebrew`, then in the project root:

```bash
xcode-select --install # install the Xcode command line tools, if you haven't already
brew bundle

code_sign=false use_carthage_cache=false ./bin/build_vimr.sh # VimR.app will be placed in build/Build/Products/Release/
```

## Project Setup

### Artifacts Hierarchy

```
VimR.app
+-- NvimView.framework
    +-- NvimServer
        +-- libnvim
        +-- other libs for Neovim
    +-- NvimView
        +-- NvimServer binary (copied by the build script)
        +-- runtime files for Neovim (copied by the build script)
```

### How to develop

See [DEVELOP.md](docs/develop.md).

## License

[MIT](https://github.com/qvacua/vimr/blob/master/LICENSE)

---

If you are here for VimR-MacVim, use the [macvim/master](https://github.com/qvacua/vimr/tree/macvim/master) branch and the version [0.8.0 (32)](https://github.com/qvacua/vimr/releases/tag/v0.8.0-32).
