VimR — Vim Refined
==================

![App Icon](https://raw.github.com/qvacua/vimr/master/Meta/vimr-app-icon.png)

[![Build Status](https://travis-ci.org/qvacua/vimr.svg?branch=master)](https://travis-ci.org/qvacua/vimr)

Download
--------

Pre-built binaries can be found [here](https://github.com/qvacua/vimr/releases).

From time to time I'll upload a bleeding edge build and you can download it [here](http://qvacua.com/snapshots/?C=M;O=D).

About
-----

Project VimR is an attempt to refine the Vim experience. The goal is to build an editor that uses Vim inside with many of the convenience GUI features similar to those present in modern editors for Mac. Let's see how far we get! :) Some features so far:

* Open Quickly à la Xcode (or Go to File in TextMate)
* File browser with many [keyboard actions](https://github.com/qvacua/vimr/wiki/File-Browser-Actions)
* Preview via a plugin system: currently VimR ships with a `markdown`-preview plugin, more to come!

In case you want to have a bit more information on the motivation behind VimR, I tried to explain it in my [blog](http://ishouldcocoa.net/post/85242609106/why-vimr).

There is a mailing list with absolute no traffic: [vimr@librelist.com](mailto:vimr@librelist.com). (To unsubscribe, send a mail to [vimr-unsubscribe@librelist.com](mailto:vimr-unsubscribe@librelist.com))

![Screenshot](https://raw.github.com/qvacua/vimr/master/Meta/screenshot.png)

How to Build
------------

First, clone the submodules:

```
$ git submodule update --recursive --init
```

Then, build the `macvim` submodule: Assuming you're in the project root

```
$ cd macvim/src
$ ./configure --with-features=huge --enable-rubyinterp --enable-pythoninterp --enable-perlinterp --enable-cscope
$ make
```

We use [CocoaPods](http://cocoapods.org) to include other open source libraries, eg [OCHamcrest](https://github.com/hamcrest/OCHamcrest) and [TBCacao](https://github.com/qvacua/tbcacao). Thus, install CocoaPods and do the following in the project root

```
$ sudo gem install cocoapods    # only if you haven't yet installed CocoaPods
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

