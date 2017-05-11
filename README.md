VimR — Neovim Refined
==================

[![Join the chat at https://gitter.im/vimr/Lobby](https://badges.gitter.im/vimr/Lobby.svg)](https://gitter.im/vimr/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

![App Icon](https://raw.github.com/qvacua/vimr/master/resources/vimr-app-icon.png)

[Download](https://github.com/qvacua/vimr/releases) • <http://vimr.org>

[![Bountysource](https://www.bountysource.com/badge/team?team_id=933&style=raised)](https://www.bountysource.com/teams/vimr?utm_source=VimR%20%E2%80%94%20Vim%20Refined&utm_medium=shield&utm_campaign=raised) [![Chat at https://gitter.im/vimr/vimr](https://badges.gitter.im/vimr/vimr.svg)](https://gitter.im/vimr/vimr?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Travis builds](https://travis-ci.org/qvacua/vimr.svg?branch=develop)](https://travis-ci.org/qvacua/vimr) [![Stories in Ready](https://badge.waffle.io/qvacua/vimr.svg?label=ready&title=Ready)](http://waffle.io/qvacua/vimr)

![Screenshot 0](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot0.png)
![Screenshot 1](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot1.png)
![Screenshot 2](https://raw.githubusercontent.com/qvacua/vimr/develop/resources/screenshot2.png)

## UPDATE

We recently, June 2016, started to migrate the MacVim backend (VimR-MacVim) to a Neovim backend. It's a complete rewrite in Swift for which we use Objective-C when appropriate.

## About

Project VimR is an attempt to refine the Neovim experience (or it is just YA Neovim GUI for mac OS). The goal is to build an editor that uses Neovim inside with many of the convenience GUI features similar to those present in modern editors. We mainly use Swift, but also use Objective-C when its C-nature helps

There are other working Neovim GUIs for OS X, e.g. [NyaoVim](https://github.com/rhysd/NyaoVim), [neovim-dot-app](https://github.com/rogual/neovim-dot-app), etc., why another?

- play around (obviously) with [Neovim](https://github.com/qvacua/neovim),
- play around with Swift (and especially with [RxSwift](https://github.com/ReactiveX/RxSwift)) and
- (most importantly) have fun!

### SwiftNeovim

[SwiftNeovim](https://github.com/qvacua/vimr/tree/master/SwiftNeovim) is VimR's Cocoa Framework which bundles everything, e.g. Neovim's `runtime`-files, needed to embed Neovim in a Cocoa App. See the [wiki](https://github.com/qvacua/vimr/wiki/SwiftNeovim-Framework) for more details.

---

If you want to support VimR financially, you can use [Bountysource](https://www.bountysource.com/teams/vimr). Big thanks to [all](https://www.bountysource.com/teams/vimr/backers) who did support: We list our spendings in the [wiki](https://github.com/qvacua/vimr/wiki/How-we-use-the-donations).

## Download

Pre-built binaries can be found under [Releases](https://github.com/qvacua/vimr/releases).

## Implemented Features

* Multiple windows.
* Basic input including Emojis and Hangul (+Hanja): We don't know whether other input systems work...
* Markdown preview
* Generic HTML preview (retains the scroll position when reloading)
* Basic mouse support: Left button actions and scrolling.
* Fuzzy file finder a la Xcode's "Open Quickly..."
* Basic trackpad support: Pinching for zooming and two-finger scrolling.
* Ligatures: Turned off by default. Turn it on in the Preferences.
* Basic File and Edit menu items.
* Command line tool.
* (Simple) File browser
* Flexible workspace model a la JetBrain's IDEs

## Planned Features

The following are features we _plan_ to implement (some of which are already present in VimR-MacVim). Bear in mind that we only recently started to completely rewrite VimR, which means it will take some time to have them all implemented. In no particular order:

* Some more standard OSX menu items.
* Improved rendering and input handling, especially Hangul/Hanja (Why is Korean so important? 🤔): The current implementation is really ugly and messy...
* ...

We will gradually create [issues](https://github.com/qvacua/vimr/issues) with more details. For the current status see the [project board](https://waffle.io/qvacua/vimr).

### Stuff with Question Marks

* Minimap
* Some kind of plugin system which utilizes the preview and the workspace model (does NSBundle-loading work in Swift, too? If yes, how does it go with code signing?)
* ...

## How to Build

First after cloning the VimR source tree you need to initialize git submodules
(right now the only one used is for neovim source tree):

```bash
git submodule init
git submodule update
```

You have to use Xcode 8. First install `homebrew`, then in the project root:

```bash
xcode-select --install # install the Xcode command line tools
brew install carthage # install Carthage for dependency management
brew install libtool automake cmake pkg-config gettext ninja # install libs and tools for neovim

./bin/build_vimr.sh # VimR.app will be placed in build/Release
```

If you encounter `/usr/local/Library/ENV/4.3/sed: No such file or directory`, then try the following:

```bash
cd neovim
make distclean
brew reinstall -s libtool
```

Then `./bin/build_vimr.sh` again in the project root folder. (See [GH-263](https://github.com/qvacua/vimr/issues/263))

## Project Setup

### Artifacts Hierarchy

```
VimR.app
+-- SwiftNeoVim.framework
    +-- NeoVimView
    +-- runtime files for Neovim
    +-- NeoVimServer
        +-- libnvim
        +-- other libs for Neovim
```

### Libraries for Neovim

* The library `libiconv` is linked by the linker flag `-liconv`. The version bundled with OSX will be linked.
* The library `libintl` should be installed by `homebrew` and is statically linked by explicitly using the linker flag `/usr/local/opt/gettext/lib/libintl.a`.
* Other libraries used by Neovim, which are automatically built by building `libnvim`, are linked by adding them to the Xcode project.

## License

[MIT](https://github.com/qvacua/vimr/blob/master/LICENSE)

---

If you are here for VimR-MacVim, use the [macvim/master](https://github.com/qvacua/vimr/tree/macvim/master) branch and the version [0.8.0 (32)](https://github.com/qvacua/vimr/releases/tag/v0.8.0-32).
