VimR — Vim Refined
==================

![App Icon](https://raw.github.com/qvacua/vimr/master/Meta/vimr-app-icon.png)

<http://vimr.org>

[![Build Status](https://travis-ci.org/qvacua/vimr.svg?branch=master)](https://travis-ci.org/qvacua/vimr) [![Bountysource](https://www.bountysource.com/badge/team?team_id=933&style=raised)](https://www.bountysource.com/teams/vimr?utm_source=VimR%20%E2%80%94%20Vim%20Refined&utm_medium=shield&utm_campaign=raised)

Download
--------

Pre-built binaries can be found [here](https://github.com/qvacua/vimr/releases).

From time to time I'll upload a bleeding edge build and you can download it [here](http://taewon.de/snapshots/?C=M;O=D).

About
-----

Project VimR is an attempt to refine the Vim experience. The goal is to build an editor that uses Vim inside with many of the convenience GUI features similar to those present in modern editors for Mac. Let's see how far we get! :) Some features so far:

* Open Quickly à la Xcode (or Go to File in TextMate)
* File browser with many [keyboard actions](https://github.com/qvacua/vimr/wiki/File-Browser-Actions)
* Preview via a plugin system: currently VimR ships with a `markdown`-preview plugin, more to come!

In case you want to have a bit more information on the motivation behind VimR, I tried to explain it in my [blog](http://ishouldcocoa.net/post/85242609106/why-vimr).

There is a mailing list with absolute no traffic: [vim-refined@googlegroups.com](mailto:vim-refined@googlegroups.com) or <https://groups.google.com/forum/#!forum/vim-refined>

Screenshots
-----------

![Screenshot](https://raw.github.com/qvacua/vimr/master/Meta/screenshot.png)
![Editing Javascript](https://raw.github.com/qvacua/vimr/master/Meta/screenshots/javascript.png)
![Editing Python](https://raw.github.com/qvacua/vimr/master/Meta/screenshots/python.png)
![Editing Ruby](https://raw.github.com/qvacua/vimr/master/Meta/screenshots/ruby.png)

How to Build
------------

First, clone the submodules:

```
$ git submodule update --recursive --init
```

Then, build the `macvim` submodule: Assuming you're in the project root

```
bin/build_macvim
```

We use [CocoaPods](http://cocoapods.org) to include other open source libraries, eg [OCHamcrest](https://github.com/hamcrest/OCHamcrest) and [TBCacao](https://github.com/qvacua/tbcacao). Thus, install CocoaPods and do the following in the project root

```
$ sudo gem install cocoapods; pod setup    # only if you haven't yet installed CocoaPods
$ pod install
```

Then, either open the `VimR.xcworkspace` file and run the `VimR` scheme or do the following in the project root

```
$ xcodebuild -workspace VimR.xcworkspace -configuration Release -scheme VimR -derivedDataPath ./build clean build
```

In case you used the above `xcodebuild` command, the `VimR.app` will be in `build/Build/Products/Release`.

From time to time, we'll edit some files of `macvim` that are not registered in the `macvim/src/MacVim/MacVim.xcodeproj` file like `macvim/src/MacVim/MMBackend.m`. In this case we have to `make` `macvim` again, ie it does not suffice to recompile `VimR` (or `macvim/src/MacVim/MacVim.xcodeproj`).

Source Code License
-------------------

For now, the source code of VimR is licensed under GNU General Public License version 3 as published by the Free Software Foundation.

