/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import RxPack
import PureLayout
import Tabs

extension NvimView {

  public struct TabEntry: Hashable, TabRepresentative {
    public static func ==(lhs: TabEntry, rhs: TabEntry) -> Bool { lhs.tabpage == rhs.tabpage }

    public var title: String
    public var isSelected = false

    public var tabpage: RxNeovimApi.Tabpage
  }

  public struct Config {

    var usesCustomTabBar: Bool
    var useInteractiveZsh: Bool
    var cwd: URL
    var nvimArgs: [String]?
    var envDict: [String: String]?
    var sourceFiles: [URL]

    public init(
      usesCustomTabBar: Bool,
      useInteractiveZsh: Bool,
      cwd: URL,
      nvimArgs: [String]?,
      envDict: [String: String]?,
      sourceFiles: [URL]
    ) {
      self.usesCustomTabBar = usesCustomTabBar
      self.useInteractiveZsh = useInteractiveZsh
      self.cwd = cwd
      self.nvimArgs = nvimArgs
      self.envDict = envDict
      self.sourceFiles = sourceFiles
    }
  }

  public enum Warning {
    case cannotCloseLastTab
    case noWriteSinceLastChange
  }

  public enum Event {

    case neoVimStopped
    case setTitle(String)
    case setDirtyStatus(Bool)
    case cwdChanged
    case bufferListChanged
    case tabChanged

    case newCurrentBuffer(NvimView.Buffer)
    case bufferWritten(NvimView.Buffer)

    case colorschemeChanged(NvimView.Theme)

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

  public enum Error: Swift.Error {

    case nvimLaunch(msg: String, cause: Swift.Error)
    case ipc(msg: String, cause: Swift.Error)
  }

  public struct Theme: CustomStringConvertible {

    public static let `default` = Theme()

    public var foreground = NSColor.textColor
    public var background = NSColor.textBackgroundColor

    public var visualForeground = NSColor.selectedMenuItemTextColor
    public var visualBackground = NSColor.selectedMenuItemColor

    public var directoryForeground = NSColor.textColor

    public init() {}

    public init(_ values: [Int]) {
      if values.count < 5 { preconditionFailure("We need 5 colors!") }

      let color = ColorUtils.colorIgnoringAlpha

      self.foreground = values[0] < 0 ? Theme.default.foreground : color(values[0])
      self.background = values[1] < 0 ? Theme.default.background : color(values[1])

      self.visualForeground = values[2] < 0 ? Theme.default.visualForeground : color(values[2])
      self.visualBackground = values[3] < 0 ? Theme.default.visualBackground : color(values[3])

      self.directoryForeground = values[4] < 0
        ? Theme.default.directoryForeground
        : color(values[4])
    }

    public var description: String {
      return "NVV.Theme<" +
             "fg: \(self.foreground.hex), bg: \(self.background.hex), " +
             "visual-fg: \(self.visualForeground.hex), visual-bg: \(self.visualBackground.hex)" +
             ">"
    }
  }
}
