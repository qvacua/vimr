# Next

* GH-775: Use the colors of the selected color scheme for the markdown preview.
* GH-792: Use the macOS Font Panel to select the font: Thank you @apaleslimghost!
    - If you select a variable width font, the rendering will be broken.
* GH-786: Improve space key handling which enables <c-space> to be mapped: Thank you @cypheon!
* Improve drawing performance.
* Dependencies updates:
    - ggreer/the_silver_searcher@a509a81
    - sparkle-project/Sparkle@1.23.0
    - ReactiveX/RxSwift@5.1.1

# 0.32.0-344

We updated the library ShortcutRecorder to the latest version. By doing so, we store the shortcuts in a different format than before. This means that after you launched this version, old versions will not be compatible with the stored shortcuts. To delete the stored shortcuts, you can use `defaults delete com.qvacua.VimR.menuitems` in Terminal.

* Show only font family names of monospace fonts.
* Set `gui_running` to `true` (GH-476).
* Improve drawing performance.
* Bugfix: The cursor is not drawn when a new window is opened.
* Bugfix: Preview in the Appearance preferences is not dark mode compatible.
* Bugfix: Shortcut buttons are not dark mode compatible.
* Dependencies updates:
    - Kentzo/ShortcutRecorder@3.1
    - httpswift/swifter@1.4.7
    - eonil/FSEvents@0.1.6
    - Quick/Nimble@8.0.5
    - sparkle-project/Sparkle@1.22.0

# 0.31.0-337

* Improve handling of file system changes for the file browser

# 0.30.0-335

* Improve Open Quickly
    - Use [The Silver Searcher](https://github.com/ggreer/the_silver_searcher)'s ignore mechanism
    - Use [ccls](https://github.com/MaskRay/ccls)' fuzzy search
* GH-730: Add "Close Window" menu item, which closes all tabs (and the VimR window).
* GH-768: Bugfix: coc.nvim does not work.
* Bugfix: VimR hangs when there are windows in which nvim is waiting for user input.
* Bugfix: Forward search in Markdown preview does not work.
* Bugfix: "Open Quickly" result rows are not dark mode compatible.
* Bugfix: Enter without selecting a result in the "Open Quickly" window results in a crash.
* Dependencies updates:
    - IBM-Swift/BlueSocket 1.0.52
    - elegantchaos/DictionaryCoding 1.0.7

# 0.29.0-329

* Dependencies updates:
    - Neovim 0.4.3

# 0.28.0-328

* Add MathJax to Markdown preview
* Dependencies updates:
    - Neovim 0.4.2

# 0.27.5

* Dependencies updates:
    - Neovim 0.3.8


# 0.27.4

* Bugfix: File Browser sometimes does not update.
* Dependencies updates:
    - Neovim 0.3.7

# 0.27.3

* GH-725: Better character spacing; thanks @tkonolige!
* Dependencies updates:
    - RxSwift/RxSwift@5.0.1
    - IBM-Swift/BlueSocket@1.0.46

# 0.27.2-323

* Update neovim to v0.3.5

# 0.27.1-322

* Notarize the app

# 0.27.0-321

* GH-720: Add option to change spacing between characters; thanks @tkonolige!

# 0.26.10-319

* Minimum macOS requirement is now 10.13 High Sierra; see GH-715
* Bugfix: Wrong closing behavior of temporary sessions
* Use Swift 5
* Dependencies updates:
    - eonil/FSEvents (instead of eonil/FileSystemEvents)

# 0.26.9-312

* Bugfix: wrong color of "Select the HTML file" button of HTML preview tool
* Bugfix: memory leak (strange behavior between `CTFontManager` and `NSFontManager`)

# 0.26.8-311

* Bugfix: memory leak

# 0.26.7-310

* Bugfix: memory leak

# 0.26.6-309

* Bugfix: The state of the "Use Concurrent Rendering" checkbox is not set correctly.
* Limit the number of "VimR Networking" processes.

# 0.26.5-308

* GH-458: Bugfix: Opening files by drag-n-dropping on VimR window does not work.
* Bugfix: Crashes when some files are deleted in the `cwd` when closing.

# 0.26.4-307

* GH-709: Bugfix: Some Unicode characters were broken when ligatures are turned off.
* Dependencies updates:
    - ReactiveX/RxSwift@4.4.2
    - Quick/nimble@8.0.1

# 0.26.3-306

* Bugfix: Memory leak.

# 0.26.2-305

* GH-425: Bind http server to localhost

# 0.26.1-304

* Fix broken "Navigate to the current buffer" of the file browser
* Dependencies updates:
    - Use FontAwesome 5 (thanks for the PR, @chriszielinski!)

# 0.26.0-303

* Minimum macOS requirement is now 10.12 Sierra.
* Optional parallel computation of glyphs. This may result in faster rendering depending on the situation.
* GH-314: You can customize the key shortcut for all menu items in the *Shortcut* preferences pane.
* GH-501: Add key shortcuts to toggle the Buffer List, Markdown Preview, and HTML Preview tools.
* GH-649: Add commands that can control some of GUI elements.
* GH-506: Set font, size and linespacing via `~/.config/nvim/ginit.vim`.
* Draw the disclosure triangle in appropriate color of the current color scheme (and improve handling of changes of `cwd` in the file browser).

# 0.25.0-297

* Neovim 0.3.4
* GH-625: `vimr --cur-env` will pass the current environment variables to the new neovim process. This will result in `virtualenv` support.
* GH-443: `vimr --line ${LINE_NUMBER} ${SOME_FILE}` will open the file and go to the given line. If the file is already open in a UI window, then that window will be selected and the cursor will be moved to the given line. This can be used for example to reverse-search LaTeX.
* GH-603: Bugfix: `Cmd-V` pastes at the wrong location in the insert mode.
* GH-659: Bugfix (introduced in a snapshot): Turning off ligatures does not really turn off ligatures.
* GH-664: Bugfix: VimR crashes for some shell configurations.
* GH-666: Adapt to the new UI-API of Neovim
* Dependencies updates:
    - ReactiveX/RxSwift@4.4.1
    - httpswift/swifter@1.4.5
    - PureLayout/PureLayout@3.1.4
    - sindresorhus/github-markdown-css@3.0.1
    - sparkle-project/Sparkle@1.21.3

# 0.24.0-282

* Neovim 0.3.0
* Some refactorings for the Neovim and the UI interface.
* GH-402: Add file associations; using definitions and icons from [MacVim](http://macvim.org/)
* GH-636: Bugfix: double cursor when entering terminal
* GH-653: Bugfix: Crashes when closing the last window with "Quit after last window closes"-option turned on.
* Bugfix: Crashes when `vimr --wait` is used, but is `Ctlr-C`'ed before closing the UI window.
* Bugfix: `vimr --wait SOME_FILE` does not exit.
* Use LuaJIT again.
* Dependencies updates:
    - sparkle-project/Sparkle@1.19.0
    - Quick/nimble@7.1.2
    - eonil/FileSystemEvents@1.0.0

# 0.23.0-275

* GH-419: File browser sorts folders on the top. (Thanks @laibulle for the PR)

# 0.22.0-273

* GH-543: Add an option in the Keys preferences to use left or/and right Option key as Meta key. (Thanks @xiehuc for the PR)
* Bugfix: Eliminate a memory leak.
* Dependencies updates:
    - ReactiveX/RxSwift@4.1.2

# 0.21.2-271

* GH-626: Bugfix: Emoji menu (`Cmd-Ctrl-Space`) does not work.
* GH-162: Bugfix: Anti-aliasing on non-Retina display is broken.

# 0.21.1-269

* GH-548: Bugfix: When using certain plugings, writing beyond the right border crashes.
* GH-620: Bugfix: Wrong underline rendering.
* Dependencies updates:
    - httpswift/swifter@1.4.0

# 0.21.0-267

* GH-605: Slightly improve scroll performance.
* GH-572: Add a slider to change the trackpad scroll sensitivity in the Advanced preferences.
* GH-614: Add a checkbox for live resizing in the Advanced preferences.
* GH-611: Prevent crashing for some users when loading the FontAwesom font for icons used for example in the file browser:
    - We still don't know why the font cannot be loaded for some users. This fix will prevent the crashes, but, then, the icons will be replaced by `?`.
* Migrate one of the few Objective-C parts to Swift (the UI bridge).
* Dependencies updates:
    - ReactiveX/RxSwift@4.1.1
    - sindresorhus/github-markdown-css@2.10.0
    - Quick/Nimble@7.0.3

# 0.20.6-261

* GH-609: Bugfix: HTML preview crashes when reloading.

# 0.20.5-259

* GH-597: Bugfix: vim-fugitive sometimes causes crashes.

# 0.20.4-256

* GH-579: Bugfix: In certain cases closing window crashes in fullscreen.
* GH-545: Bugfix: Focus is lost when entering/exiting fullscreen.

# 0.20.3-255

* Bugfix: "Focus Neovim View" does not work.

# 0.20.2-254

* GH-571: Bugfix: Read-only buffers are considered as modified. For example NERDTree buffers won't trigger the "Please save first" dialog anymore.
* GH-387: Show all buffers (the same as `:buffers`) in the buffers list
* GH-553: Bugfix: Do not crash when there's an error in `init.vim`.
* Improve forward- and reverse-search for Markdown previews.
* High Sierra related fixes
    - Do not crash on launch
    - Too narrow entries in the file browser and buffers list.

# 0.20.1-245

* GH-580: Bugfix: Memory leak

# 0.20.0-238

* GH-534: `Cmd-D` for "Discard and Close/Quit" buttons. (thanks @nclark for the PR)
* GH-521: Improve the performance of the file browser, especically for folders like `node_modules` which contains many many files.
* GH-544: Migrate to Swift 4
* GH-528, GH-358: Add rudimentary support for Touch Bar. (thanks @greg for the PR)
* Dependencies updates:
    - neovim/neovim@v0.2.2
    - ReactiveX/RxSwift@4.0.0
    - sindresorhus/github-markdown-css@2.9.0

# 0.19.1-229

* GH-485: Bugfix: When using a dark theme the title is very difficult to read.

# 0.19.0-226

* GH-492: Improve `Control` key handling: e.g. `Ctrl-6` works now. (thanks @nhtzr for the PR)
* GH-482, GH-283 Improve Emoji + CJK + Greek text rendering. (thanks @nhtzr for the PR)
* GH-325: Improve how the window position and size are stored.
* GH-491: Bugfix: Closing the window in full screen mode crashes the app.
* GH-512: Bugfix: Intermittent crashes when closing windows or quitting the app.
* Dependencies updates:
    - ReactiveX/RxSwift@3.6.1
    - sparkle-project/Sparkle@1.18.1
    - sindresorhus/github-markdown-css@2.8.0
    - Quick/Nimble@7.0.1

# 0.18.0-217

* GH-481: Bugfix: Quiting with `:qa!` warns about buffers that are already gone. (thanks @nhtzr for the PR)
* GH-458: Drag & Drop of files onto the main window works. (thanks @nhtzr for the PR)
* GH-487: Hide the mouse cursor when typing. (thanks @nhtzr for the PR)
* GH-315: Enable mapping of `<C-Tab>` and `<C-S-Tab>`. (thanks @nhtzr for the PR)
* GH-368: Send `FocusGained` and `FocusLost` event to neovim backend. (thanks @nhtzr for the PR)

# 0.17.0-213

* GH-436: Use colors from the selected `colorscheme` for tools, e.g. the file browser:
    - Use the `directory` color for folders in the file browser.
    - Use slightly darker version of the `background` color for the window title bar.
    - Add an option to turn off file icons in the file browser and in the buffer list in case the `colorscheme` does not play well with them, cf. GH-479.

# 0.16.2-210

* GH-472: Bugfix: Mouse wheel scrolling in split window sometimes scrolls in the wrong split.

# 0.16.1-208

* GH-472: Bugfix: mouse scrolling an out-of-focus split window scrolls the focused split window.

# 0.16.0-205

* GH-378: Draw curly underline, e.g. when the spelling is incorrect.
* GH-326, GH-460: Add an option to hide or quit VimR when the last window closes. This is for example useful when you want to use VimR as `git difftool` as described below.
* GH-302, GH-421: The `vimr` CLI tool has two new options:
  - `--wait`: When present, the `vimr` CLI tool will exit only after the corresponding VimR window has been closed. This is particularly useful when combined with the `--nvim` option as described below.
  - `--nvim`: When present, all command line arguments except `--dry-run` and `--wait`, see above, will be passed over to the background `nvim` process when launching. This means that you can now use for example the `-d` option to activate the diffmode. To use VimR as `git difftool`, add the following to your `~/.gitconfig`
    ```
    [difftool "vimrdiff"]
      cmd = vimr --wait --nvim -d $LOCAL $REMOTE
    [diff]
      tool = vimrdiff
    ```
  You have to re-install the `vimr` CLI tool in the Preferences window as described in the [wiki](https://github.com/qvacua/vimr/wiki#command-line-tool).
* Reduce the binary size by approx. 8 MB: We compile httpswift/swifter directly into VimR's binary...
* Bonus: The Neovim splash screen shows up!

# 0.15.2-201

* Bugfix: The state of the tools of a new window is not the same as the last active window.
* GH-423: Bugfix: `lcd` and `tcd` does not work correctly when switching tabs.

# 0.15.1-199

* Improved scroll performance.
* GH-450: Bugfix: Crashes when a hidden file gets deleted in the `cwd`.
* GH-395: Bugfix: Massive file system changes in the working directory causes VimR to freeze.
* GH-430: Bugfix: The cursor disappears when using arrow keys in the command mode.
* GH-403, GH-447: `Shift-Tab` works (thanks to @mkhl)
* Dependencies updates:
    - neovim/neovim@1b2acb8d958c1c8e2f382c2de9c98586801fd9fe
    - ReactiveX/RxSwift@3.5.0

# 0.15.0-191

* We now compile `gettext` ourselves and do not use the pre-built version from homebrew: The library from homebrew is built for 10.12 and VimR's deployment target it 10.10. This mismatch produced many warnings during compilation time...
* GH-426: You can now turn off some or all tools, e.g. file browser.
* GH-434: Bugfix: `autochdir` does not work.
* Bugfix: When you hide all tools, the state does not get stored in the user defaults.
* `set mouse=a` when launching the neovim process.
* Dependencies updates:
    - neovim/neovim@v0.2.0
    - ReactiveX/RxSwift@3.4.1

# 0.14.3-185

* GH-440: Bugfix: "User interactive mode for zsh" does not work.

# 0.14.2-184

* GH-438: Bugfix: `:help` does not work.

# 0.14.1-182

* Make app launch time much faster.

# 0.14.0-181

* GH-405: Redesign
    - Redux-like architecture using RxSwift
* GH-383: Add a general web view preview which preserves the scroll position when (automatically) reloading the selected file.
* GH-398: Set the represented icon in the window title bar.
* GH-389: Bugfix: The Files tool does not update when one folder is created.
* GH-374: Bugfix: The tool buttons have a narrow area which does not react to mouse down when the tool is closed.
* Dependencies updates:
    - RxSwift: 3.4.0
    - Sparkle: 1.17
    - github-markdown-css: 2.6.0
    - swifter: 1.3.3
    - Nimble: 6.1.0
    - neovim: neovim/neovim@337299c8082347feecb5e733bed993c6a5933456

# 0.13.1-167

* Make pinch-zooming fast (enough) on Retina-displays.
* Make markdown previewing more robust against non-existing file.
* GH-392: Bugfix: fix a weird scroll issue.
* GH-371: Small scroll performance improvment.

# 0.13.0-164

* GH-339: Add a simple markdown previewer.

# 0.12.6-162

* GH-382: Bugfix: Sometimes the working directory is not set correctly when using the command line tool `vimr`.

# 0.12.5-159

* GH-376: Bugfix: Sometimes the communication between the UI and the Neovim backend breaks.

# 0.12.4-156

* GH-376: Fix a part of the bug. There's still an issue, cf. discussions in GH-376.

# 0.12.3-154

* GH-376: Bugfix: Exiting full-screen sometimes causes crashes.
* Update RxSwift to [3.1.0](https://github.com/ReactiveX/RxSwift/releases/tag/3.1.0)

# 0.12.2-153

* Bugfix: Store preferences correctly.
* GH-292: Improve Open Quickly results
* Update Sparkle to [0.15.1](https://github.com/sparkle-project/Sparkle/releases/tag/1.15.1)

# 0.12.1-151

* Fix memory leak

# 0.12.0-150

* GH-360: Bugfix: a buffer list related bug.
* GH-363: Upgrade to jemalloc 4.4.0 for 10.10 (and 10.11)
* GH-293: More tool, i.e. file browser and buffer list improvements
    - option to show hidden files
    - move tool to top/right/bottom/left
    - add a button for `cd ..`
    - select the currently open file: "Scroll from source" from IntelliJ
* GH-369: Bugfix: set the `cwd` correctly when opening files using the `vimr` command line tool

# 0.11.1-140

* GH-354: Bugfix: a file browser related bug.

# 0.11.0-138

* GH-341: Do not become unresponsive when opening a file with existing swap file via the file browser. (This bug was introduced with GH-299)
* GH-347: Do not become unresponsive when you `wq` the last tab or buffer.
* GH-297: Add a buffer list tool.
* GH-296: Drag & drop tools, currently the file browser and the buffer list, to any side of the window! 😀
* GH-351: Improve file browser updating. It also became better at keeping the expanded states of folders.
* Make `Cmd-V` a bit better
* neovim/neovim@42033bc5bd4bd0f06b33391e12672900bc21b993

# 0.10.2-127

* GH-332: Turn on `paste` option before `Cmd-V`ing (and reset the value)
* GH-333: Set `$LANG` to `utf-8` such that non-ASCII characters are not garbled when copied to the system clipboard.
    - GH-337: With the first version of GH-333, strangely, on 10.12.X `init.vim` did not get read. GH-337 fixes this issue.
* GH-334: `set` `title` and `termguicolors` by default such that airline works without changing `init.vim`.
* GH-276: Draw a different, i.e. thin, cursor in the insert mode.
* GH-299: Add a context menu to the file browser.
* GH-237: Increase mouse scrollwheel sensitivity.
* neovim/neovim@598f5af58b21747ea9d6dc0a7d846cb85ae52824

# 0.10.1-122

* GH-321: `Cmd-V` now works in the terminal mode.
* GH-330: Closing the file browser with `Cmd-1` now focuses the Neovim view.
* GU-308: Set `cwd` to the parent folder of the file when opening a file in a new window 
* Update RxSwift from `3.0.0-rc1` to `3.0.1`
* Update Neovim to neovim/neovim@0213e99aaf6eba303fd459183dd14a4a11cc5b07
    - includes `inccommand`! 😆

# 0.10.0-118

* GH-309: When opening a file via a GUI action, check whether the file is already open.
    - Open in a tab or split: select the tab/split
    - Open in another (GUI) window: let NeoVim handle it.
* GH-239, GH-312: Turn on font smoothing such that the 'Use LCD font smoothing when available' setting from the General system preferences pane is respected.
* GH-270: Make line spacing configurable via the 'Appearances' preferences pane.
* GH-322: Fix crashes related to the file browser.
* Bugfix: The command line tool `vimr` sometimes does not open the files in the frontmost window.

# 0.9.0-112

## First release of VimR with NeoVim backend

* NeoVim rulez! 😆 (neovim/neovim@5bcb7aa8bf75966416f2df5a838e5cb71d439ae7)
* Pinch to zoom in or out
* Simple file browser
* Open quickly a la Xcode
* Ligatures support
* Command line tool
