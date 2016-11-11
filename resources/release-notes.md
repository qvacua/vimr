# next

* GH-332: Turn on `paste` option before `Cmd-V`ing (and reset the value)
* GH-333: Set `$LANG` to `utf-8` such that non-ASCII characters are not garbled when copied to the system clipboard.

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

* NeoVim rulez! ?? (neovim/neovim@5bcb7aa8bf75966416f2df5a838e5cb71d439ae7)
* Pinch to zoom in or out
* Simple file browser
* Open quickly a la Xcode
* Ligatures support
* Command line tool
