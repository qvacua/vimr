# next

* GH-360 Bugfix: a buffer list related bug.
* GH-363: Accidentaly included the (problematic for pre 10.12) jemalloc upgrade for Neovim. Revert it.

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
