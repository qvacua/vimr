/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import PureLayout
import RxNeovim
import RxPack
import Tabs

public extension NvimView {
  struct TabEntry: Hashable, TabRepresentative {
    public static func == (lhs: TabEntry, rhs: TabEntry) -> Bool { lhs.tabpage == rhs.tabpage }

    public var title: String
    public var isSelected = false

    public var tabpage: RxNeovimApi.Tabpage
  }

  struct Config {
    var usesCustomTabBar: Bool
    var useInteractiveZsh: Bool
    var cwd: URL
    var nvimBinary: String
    var nvimArgs: [String]?
    var envDict: [String: String]?
    var sourceFiles: [URL]

    public init(
      usesCustomTabBar: Bool,
      useInteractiveZsh: Bool,
      cwd: URL,
      nvimBinary: String,
      nvimArgs: [String]?,
      envDict: [String: String]?,
      sourceFiles: [URL]
    ) {
      self.usesCustomTabBar = usesCustomTabBar
      self.useInteractiveZsh = useInteractiveZsh
      self.cwd = cwd
      self.nvimBinary = nvimBinary
      self.nvimArgs = nvimArgs
      self.envDict = envDict
      self.sourceFiles = sourceFiles
    }
  }

  enum Warning {
    case cannotCloseLastTab
    case noWriteSinceLastChange
  }

  enum Event {
    case neoVimStopped
    case setTitle(String)
    case setDirtyStatus(Bool)
    case cwdChanged
    case bufferListChanged
    case tabChanged

    case newCurrentBuffer(NvimView.Buffer)
    case bufferWritten(NvimView.Buffer)

    case colorschemeChanged(NvimView.Theme)
    case guifontChanged(NSFont)

    case ipcBecameInvalid(String)

    case scroll
    case cursor(Position)

    case rpcEvent([MessagePack.MessagePackValue])
    case rpcEventSubscribed

    case warning(Warning)

    case initVimError

    // FIXME: maybe do onError()?
    case apiError(msg: String, cause: Swift.Error)
  }

  enum Error: Swift.Error {
    case nvimLaunch(msg: String, cause: Swift.Error)
    case ipc(msg: String, cause: Swift.Error)
  }

  struct Theme: CustomStringConvertible {
    public static let `default` = Theme()

    public var foreground = NSColor.textColor
    public var background = NSColor.textBackgroundColor

    public var visualForeground: NSColor =
      .init(named: NSColor.Name("controlAccentColor")) ?? .selectedMenuItemTextColor
    // NSColor.selectedMenuItemTextColor
    // NSColor.selectedMenuItemColor is deprecated. The doc says that
    // NSVisualEffectView.Material.selection should be used instead, but I don't know how to get
    // an NSColor from it.
    public var visualBackground = NSColor.selectedContentBackgroundColor

    public var directoryForeground = NSColor.textColor

    public var tabForeground = NSColor.controlColor
    public var tabBackground = NSColor.controlBackgroundColor

    public var tabBarForeground = NSColor.textColor
    public var tabBarBackground = NSColor.windowBackgroundColor

    public var selectedTabForeground = NSColor.selectedTextColor
    public var selectedTabBackground = NSColor.selectedTextBackgroundColor

    public init() {}

    public init(_ values: [Int]) {
      if values.count < 11 { preconditionFailure("We need 11 colors!") }

      let color = ColorUtils.colorIgnoringAlpha

      self.foreground = values[0] < 0 ? Theme.default.foreground : color(values[0])
      self.background = values[1] < 0 ? Theme.default.background : color(values[1])

      self.visualForeground = values[2] < 0 ? Theme.default.visualForeground : color(values[2])
      self.visualBackground = values[3] < 0 ? Theme.default.visualBackground : color(values[3])

      self.directoryForeground = values[4] < 0
        ? Theme.default.directoryForeground
        : color(values[4])

      self.tabBarBackground = values[5] < 0 ? Theme.default.tabBarBackground : color(values[5])
      self.tabBarForeground = values[6] < 0 ? Theme.default.tabBarForeground : color(values[6])

      self.tabBackground = values[7] < 0 ? Theme.default.tabBackground : color(values[7])
      self.tabForeground = values[8] < 0 ? Theme.default.tabForeground : color(values[8])

      self.selectedTabBackground = values[9] < 0 ? Theme.default
        .selectedTabBackground : color(values[9])
      self.selectedTabForeground = values[10] < 0 ? Theme.default
        .selectedTabForeground : color(values[10])
    }

    public var description: String {
      "NVV.Theme<" +
        "fg: \(self.foreground.hex), bg: \(self.background.hex), " +
        "visual-fg: \(self.visualForeground.hex), visual-bg: \(self.visualBackground.hex)" +
        "tab-fg: \(self.tabForeground.hex), tab-bg: \(self.tabBackground.hex)" +
        "tabfill-fg: \(self.tabBarForeground.hex), tabfill-bg: \(self.tabBarBackground.hex)" +
        "tabsel-fg: \(self.selectedTabForeground.hex), tabsel-bg: \(self.selectedTabBackground.hex)" +
        ">"
    }
  }
}
