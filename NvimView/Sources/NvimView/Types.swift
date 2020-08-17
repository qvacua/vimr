/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

public struct FontTrait: OptionSet {
  public let rawValue: UInt

  static let none = FontTrait(rawValue: 0)
  static let italic = FontTrait(rawValue: (1 << 0))
  static let bold = FontTrait(rawValue: (1 << 1))
  static let underline = FontTrait(rawValue: (1 << 2))
  static let undercurl = FontTrait(rawValue: (1 << 3))
  
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }
}

public enum RenderDataType: Int {
  case rawLine
  case goto
  case scroll
}

enum NvimServerMsgId: Int {
  case serverReady = 0
  case nvimReady
  case resize
  case clear
  case setMenu
  case busyStart
  case busyStop
  case modeChange
  case modeInfoSet
  case bell
  case visualBell
  case flush
  case highlightAttrs
  case setTitle
  case stop
  case optionSet

  case dirtyStatusChanged
  case cwdChanged
  case colorSchemeChanged
  case defaultColorsChanged
  case autoCommandEvent
  case rpcEventSubscribed

  case fatalError

  case debug1
}

enum NvimServerFatalErrorCode: Int {
  case localPort = 1
  case remotePort
}

enum NvimBridgeMsgId: Int {
  case agentReady = 0
  case readyForRpcEvents
  case deleteInput
  case resize
  case scroll

  case focusGained

  case debug1
}
