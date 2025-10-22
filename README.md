# VimR — Neovim GUI for macOS

[Download](https://github.com/qvacua/vimr/releases) • [Documentation](https://github.com/qvacua/vimr/wiki)

![Screenshot 1](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot1.png)
![Screenshot 2](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot2.png)

## About

VimR is a Neovim GUI for macOS written in Swift.

The goal is to build an editor that uses Neovim inside with some of the convenient
GUI features similar to those present in other editors.

There are other Neovim GUIs for macOS,
see the [list](https://github.com/neovim/neovim/wiki/Related-projects#gui), so why?

- Play around with [Neovim](https://github.com/qvacua/neovim),
- Play around with the main idea of Redux architecture, and
- (most importantly) have fun!

If you feel chatty, there is a chat room: <https://matrix.to/#/#vimr:matrix.org>

If you want to support VimR financially, use [Github's Sponsor](https://github.com/sponsors/qvacua).

## Download

Pre-built Universal signed and notarized binaries can be found under [Releases](https://github.com/qvacua/vimr/releases).

## Reusable Components

* [NvimView](https://github.com/qvacua/vimr/tree/master/NvimView): SwiftPM module containing
  an NSView which bundles everything, e.g., Neovim binary and its `runtime`-files, needed to 
  embed Neovim in a Cocoa App.
* [NvimApi](https://github.com/qvacua/vimr/tree/master/NvimApi): API for Neovim; sync and async.

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
git submodule update --init

xcode-select --install # install the Xcode command line tools, if you haven't already
brew bundle # install dependencies, e.g., build tools for Neovim
clean=true notarize=false ./bin/build_vimr.sh
# VimR.app will be placed in ./build/Build/Products/Release/
```

## Development

See [DEVELOP.md](DEVELOP.md).

## License

[MIT](https://github.com/qvacua/vimr/blob/master/LICENSE)
