/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import ShortcutRecorder

let defaultShortcuts: [String: [String: Any]] = [
  "com.qvacua.vimr.menuitems.edit.copy": [
    SRShortcutCharacters: "c",
    SRShortcutCharactersIgnoringModifiers: "c",
    SRShortcutKeyCode: 8,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.edit.cut": [
    SRShortcutCharacters: "x",
    SRShortcutCharactersIgnoringModifiers: "x",
    SRShortcutKeyCode: 7,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.edit.delete": [String: Any](),
  "com.qvacua.vimr.menuitems.edit.paste": [
    SRShortcutCharacters: "v",
    SRShortcutCharactersIgnoringModifiers: "v",
    SRShortcutKeyCode: 9,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.edit.redo": [
    SRShortcutCharacters: "z",
    SRShortcutCharactersIgnoringModifiers: "Z",
    SRShortcutKeyCode: 6,
    SRShortcutModifierFlagsKey: 1179914,
  ],
  "com.qvacua.vimr.menuitems.edit.select-all": [
    SRShortcutCharacters: "a",
    SRShortcutCharactersIgnoringModifiers: "a",
    SRShortcutKeyCode: 0,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.edit.undo": [
    SRShortcutCharacters: "z",
    SRShortcutCharactersIgnoringModifiers: "z",
    SRShortcutKeyCode: 6,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.file.close": [
    SRShortcutCharacters: "w",
    SRShortcutCharactersIgnoringModifiers: "w",
    SRShortcutKeyCode: 13,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.file.new": [
    SRShortcutCharacters: "n",
    SRShortcutCharactersIgnoringModifiers: "n",
    SRShortcutKeyCode: 45,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.file.new-tab": [
    SRShortcutCharacters: "t",
    SRShortcutCharactersIgnoringModifiers: "t",
    SRShortcutKeyCode: 17,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.file.open-in-new-window": [
    SRShortcutCharacters: "ø",
    SRShortcutCharactersIgnoringModifiers: "o",
    SRShortcutKeyCode: 31,
    SRShortcutModifierFlagsKey: 1573160,
  ],
  "com.qvacua.vimr.menuitems.file.open-quickly": [
    SRShortcutCharacters: "o",
    SRShortcutCharactersIgnoringModifiers: "O",
    SRShortcutKeyCode: 31,
    SRShortcutModifierFlagsKey: 1179914,
  ],
  "com.qvacua.vimr.menuitems.file.open": [
    SRShortcutCharacters: "o",
    SRShortcutCharactersIgnoringModifiers: "o",
    SRShortcutKeyCode: 31,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.file.save-as": [
    SRShortcutCharacters: "s",
    SRShortcutCharactersIgnoringModifiers: "S",
    SRShortcutKeyCode: 1,
    SRShortcutModifierFlagsKey: 1179914,
  ],
  "com.qvacua.vimr.menuitems.file.save": [
    SRShortcutCharacters: "s",
    SRShortcutCharactersIgnoringModifiers: "s",
    SRShortcutKeyCode: 1,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.help.vimr-help": [String: Any](),
  "com.qvacua.vimr.menuitems.tools.focus-neovim-view": [
    SRShortcutCharacters: ".",
    SRShortcutCharactersIgnoringModifiers: ".",
    SRShortcutKeyCode: 47,
    SRShortcutModifierFlagsKey: 1048576,
  ],
  "com.qvacua.vimr.menuitems.tools.toggle-all-tools": [
    SRShortcutCharacters: "\\",
    SRShortcutCharactersIgnoringModifiers: "\\",
    SRShortcutKeyCode: 42,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.tools.toggle-file-browser": [
    SRShortcutCharacters: "1",
    SRShortcutCharactersIgnoringModifiers: "1",
    SRShortcutKeyCode: 18,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.tools.toggle-buffer-list": [
    SRShortcutCharacters: "1",
    SRShortcutCharactersIgnoringModifiers: "2",
    SRShortcutKeyCode: 19,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.tools.toggle-markdown-preview": [
    SRShortcutCharacters: "1",
    SRShortcutCharactersIgnoringModifiers: "3",
    SRShortcutKeyCode: 20,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.tools.toggle-html-preview": [
    SRShortcutCharacters: "1",
    SRShortcutCharactersIgnoringModifiers: "4",
    SRShortcutKeyCode: 21,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.tools.toggle-tool-buttons": [
    SRShortcutCharacters: "\\",
    SRShortcutCharactersIgnoringModifiers: "|",
    SRShortcutKeyCode: 42,
    SRShortcutModifierFlagsKey: 1179914,
  ],
  "com.qvacua.vimr.menuitems.view.enter-full-screen": [
    SRShortcutCharacters: "\006",
    SRShortcutCharactersIgnoringModifiers: "f",
    SRShortcutKeyCode: 3,
    SRShortcutModifierFlagsKey: 1319176,
  ],
  "com.qvacua.vimr.menuitems.view.font.bigger": [
    SRShortcutCharacters: "=",
    SRShortcutCharactersIgnoringModifiers: "=",
    SRShortcutKeyCode: 24,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.view.font.reset-to-default-size": [
    SRShortcutCharacters: "0",
    SRShortcutCharactersIgnoringModifiers: "0",
    SRShortcutKeyCode: 29,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.view.font.smaller": [
    SRShortcutCharacters: "-",
    SRShortcutCharactersIgnoringModifiers: "-",
    SRShortcutKeyCode: 27,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.window.bring-all-to-front": [String: Any](),
  "com.qvacua.vimr.menuitems.window.minimize": [
    SRShortcutCharacters: "m",
    SRShortcutCharactersIgnoringModifiers: "m",
    SRShortcutKeyCode: 46,
    SRShortcutModifierFlagsKey: 1048840,
  ],
  "com.qvacua.vimr.menuitems.window.zoom": [String: Any](),
]
