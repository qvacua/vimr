# VimR — Neovim GUI for macOS

[Download](https://github.com/qvacua/vimr/releases) • [Documentation](https://github.com/qvacua/vimr/wiki)

![Screenshot 1](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot1.png)
![Screenshot 2](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot2.png)

## About

Project VimR is a Neovim GUI for macOS.
The goal is to build an editor that uses Neovim inside with many of the convenience
GUI features similar to those present in modern editors. We mainly use Swift,
but also use C/Objective-C when where appropriate.

There are other Neovim GUIs for macOS, see the [list](https://github.com/neovim/neovim/wiki/Related-projects#gui), so why?

- Play around with [Neovim](https://github.com/qvacua/neovim),
- play around with Swift (and especially with [RxSwift](https://github.com/ReactiveX/RxSwift)), and
- (most importantly) have fun!

If you want to support VimR financially, use [Github's Sponsor](https://github.com/sponsors/qvacua).

## Download

Pre-built Universal signed and notarized binaries can be found under [Releases](https://github.com/qvacua/vimr/releases).

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

Clone this repository. Install `homebrew`, then in the project root:

```bash
xcode-select --install # install the Xcode command line tools, if you haven't already
brew bundle

code_sign=false use_carthage_cache=false download_deps=true ./bin/build_vimr.sh
# VimR.app will be placed in ./build/Build/Products/Release/
```

## Development

See [DEVELOP.md](DEVELOP.md).

## License

[MIT](https://github.com/qvacua/vimr/blob/master/LICENSE)

