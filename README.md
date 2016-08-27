VimR — Vim Refined
==================

![App Icon](https://raw.github.com/qvacua/vimr/master/resources/vimr-app-icon.png)

[Pre-built binaries](https://github.com/qvacua/vimr/releases) • <http://vimr.org>

[![Bountysource](https://www.bountysource.com/badge/team?team_id=933&style=raised)](https://www.bountysource.com/teams/vimr?utm_source=VimR%20%E2%80%94%20Vim%20Refined&utm_medium=shield&utm_campaign=raised)

![Screenshot](https://raw.githubusercontent.com/qvacua/vimr/master/resources/screenshot.png)

## UPDATE

We recently, June 2016, started to migrate the MacVim backend (VimR-MacVim) to a NeoVim backend. It's a complete rewrite in Swift for which we use Objective-C when appropriate. We experimented with NeoVim a bit ([nvox](https://github.com/qvacua/nvox)) and now we are confident enough to think that VimR can be backed by NeoVim. It will take some time though till the transition/rewrite is complete. Bear with us!

If you are here for VimR-MacVim, use the [macvim/master](https://github.com/qvacua/vimr/tree/macvim/master) branch and the version [0.8.0 (32)](https://github.com/qvacua/vimr/releases/tag/v0.8.0-32).

## About

Project VimR is an attempt to refine the Vim experience. The goal is to build an editor that uses NeoVim inside with many of the convenience GUI features similar to those present in modern editors.

There are other working NeoVim GUIs for OS X, e.g. [NyaoVim](https://github.com/rhysd/NyaoVim), [neovim-dot-app](https://github.com/rogual/neovim-dot-app), etc., why another?

- play around (obviously) with [NeoVim](https://github.com/qvacua/neovim),
- play around with Swift (and especially with [RxSwift](https://github.com/ReactiveX/RxSwift)) and
- (most importantly) have fun!


### SwiftNeoVim

[SwiftNeoVim](https://github.com/qvacua/vimr/tree/master/SwiftNeoVim) is VimR's Cocoa Framework which bundles everything, e.g. NeoVim's `runtime`-files, needed to embed NeoVim in a Cocoa App. It is really easy to embed NeoVim in your own App: Just add an instance of `NeoVimView` somewhere in your App and that's it! 😎 (You can treat it as any other `NSView`-subclasses)

TBD: More details.

---

If you want to support VimR financially, you can use [Bountysource](https://www.bountysource.com/teams/vimr). Big thanks to [all](https://www.bountysource.com/teams/vimr/backers) who did support: We've spent the first 99€ for a year's worth of Apple's Developer Program as you may have noticed from the code-signed snapshot builds. Seriously you guys@Apple; You should make it free for free App makers and open source developers.

## Download

Pre-built binaries can be found under [Releases](https://github.com/qvacua/vimr/releases).

## Already Implemented Features

* Multiple windows.
* Basic input including Emojis and Hangul (+Hanja): We don't know whether other input systems work...
* Basic mouse support: Left button actions and scrolling.
* Basic trackpad support: Pinching for zooming.
* Ligatures: Turned off by default. Turn it on in the Preferences.
* Basic File and Edit menu items.
* Command line tool

## Planned Features

The following are features we _plan_ to implement (some of which are already present in VimR-MacVim). Bear in mind that we only recently started to completely rewrite VimR, which means it will take some time to have them all implemented. In no particular order:

* Some more standard OSX menu items.
* Improved rendering and input handling, especially Hangul/Hanja (Why is Korean so important? 🤔): The current implementation is really ugly and messy...
* Fuzzy file finder a la Xcode's "Open Quickly..."
* File browser
* Flexible workspace model a la JetBrain's IDEs: For this we'd probably port and extend [qvworkspace](https://github.com/qvacua/qvworkspace) to Swift
* Preview for some file types, e.g. Markdown, HTML, etc.
* ...

We will gradually create [issues](https://github.com/qvacua/vimr/issues) with more details.

### Stuff with Question Marks

* Minimap
* Some kind of plugin system which utilizes the preview and the workspace model (does NSBundle-loading work in Swift, too? If yes, how does it go with code signing?)
* ...

## How to Build

First install `homebrew`, then:

```bash
xcode-select --install # install the Xcode command line tools
brew install carthage # install Carthage for dependency management
brew install libtool automake cmake pkg-config gettext ninja # install libs and tools for neovim

carthage update --platform osx

git submodule update --init
cd neovim
ln -s ../local.mk local.mk
cd ..

xcodebuild -configuration Release -target VimR # VimR.app will be placed in build/Release
```

If you encounter `/usr/local/Library/ENV/4.3/sed: No such file or directory`, then try the following:

```bash
cd neovim
make distclean
brew reinstall -s libtool
```

Then `xcodebuild` again in the project root folder. (See [GH-263](https://github.com/qvacua/vimr/issues/263))

## Project Setup

### Artifacts Hierarchy

```
VimR.app
+-- SwiftNeoVim.framework
    +-- NeoVimView
    +-- runtime files for NeoVim
    +-- NeoVimServer
        +-- libnvim
        +-- other libs for NeoVim
```

### Libraries for NeoVim

* The library `libiconv` is linked by the linker flag `-liconv`. The version bundled with OSX will be linked.
* The library `libintl` should be installed by `homebrew` and is statically linked by explicitly using the linker flag `/usr/local/opt/gettext/lib/libintl.a`.
* Other libraries used by NeoVim, which are automatically built by building `libnvim`, are linked by adding them to the Xcode project.

## License

The MIT License (MIT)

Copyright (c) 2016 Tae Won Ha

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
