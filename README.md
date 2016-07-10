VimR — Vim Refined
==================

![App Icon](https://raw.github.com/qvacua/vimr/master/resources/vimr-app-icon.png)

<http://vimr.org>

[![Bountysource](https://www.bountysource.com/badge/team?team_id=933&style=raised)](https://www.bountysource.com/teams/vimr?utm_source=VimR%20%E2%80%94%20Vim%20Refined&utm_medium=shield&utm_campaign=raised)

UPDATE
------

We recently, June 2016, started to migrate the MacVim backend (VimR-MacVim) to a NeoVim backend. We experimented with NeoVim a bit ([nvox](https://github.com/qvacua/nvox)) and now we are confident enough to think that VimR can be backed by NeoVim. It will take some time though till the transition is complete. Bear with us!

If you want to build VimR-MacVim, use the [macvim/master](https://github.com/qvacua/vimr/tree/macvim/master) branch.

Since VimR-MacVim is not developed anymore, we also closed all issues involving VimR-MacVim. 

About
-----

Project VimR is an attempt to refine the Vim experience. The goal is to build an editor that uses Vim inside with many of the convenience GUI features similar to those present in modern editors for Mac.


Download
--------

Pre-built binaries can be found [here](https://github.com/qvacua/vimr/releases).

From time to time I'll upload a bleeding edge build and you can download it [here](http://taewon.de/snapshots/?C=M;O=D).

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
make CMAKE_BUILD_TYPE=Release libnvim # optional, the nvox target in Xcode also does this
```

Run the `nvox`-target in Xcode.

## Project Setup

### Artifacts Hierarchy

```
nvox.app
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
