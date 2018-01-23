/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class UiBridge {

  weak var nvimView: NvimView?

  let nvimQuitCondition = NSCondition()

  private(set) var isNvimQuitting = false
  private(set) var isNvimQuit = false

  init(uuid: String, config: NvimView.Config) {
    self.uuid = uuid
    self.messageHandler = MessageHandler()

    self.useInteractiveZsh = config.useInteractiveZsh
    self.nvimArgs = config.nvimArgs ?? []
    self.cwd = config.cwd

    self.messageHandler.bridge = self
  }

  func runLocalServerAndNvim(width: Int, height: Int) -> Bool {
    self.initialWidth = width
    self.initialHeight = height

    self.localServerThread = ThreadWithBlock(threadInitBlock: { _ in self.runLocalServer() })
    self.localServerThread?.start()

    self.launchNvimUsingLoginShell()

    let deadline = Date().addingTimeInterval(timeout)
    self.nvimReadyCondition.lock()
    defer { self.nvimReadyCondition.unlock() }
    while (!self.isNvimReady && self.nvimReadyCondition.wait(until: deadline)) {}

    return !self.isInitErrorPresent
  }

  func vimInput(_ str: String) {
    self.sendMessage(msgId: .input, data: str.data(using: .utf8))
  }

  func vimInputMarkedText(_ markedText: String) {
    self.sendMessage(msgId: .inputMarked, data: markedText.data(using: .utf8))
  }

  func deleteCharacters(_ count: Int) {
    self.sendMessage(msgId: .delete, data: [count].data())
  }

  func resize(width: Int, height: Int) {
    self.sendMessage(msgId: .resize, data: [width, height].data())
  }

  func focusGained(_ gained: Bool) {
    self.sendMessage(msgId: .focusGained, data: [gained].data())
  }

  func scroll(horizontal: Int, vertical: Int, at position: Position) {
    self.sendMessage(msgId: .scroll, data: [horizontal, vertical, position.row, position.column].data())
  }

  func quit() {
    self.isNvimQuitting = true

    self.closePorts()

    self.nvimServerProc?.waitUntilExit()

    self.nvimQuitCondition.lock()
    defer {
      self.nvimQuitCondition.signal()
      self.nvimQuitCondition.unlock()
    }
    self.isNvimQuit = true

    self.logger.info("NvimServer \(self.uuid) exited successfully.")
  }

  func forceQuit() {
    self.logger.info("Force-exiting NvimServer \(self.uuid).")

    self.isNvimQuitting = true

    self.closePorts()
    self.forceExitNvimServer()

    self.nvimQuitCondition.lock()
    defer {
      self.nvimQuitCondition.signal()
      self.nvimQuitCondition.unlock()
    }
    self.isNvimQuit = true

    self.logger.info("NvimServer \(self.uuid) was forcefully exited.")
  }

  func debug() {
    self.sendMessage(msgId: .debug1, data: nil)
  }

  fileprivate func handleMessage(msgId: Int32, data: Data?) {
    guard let msg = NvimServerMsgId(rawValue: Int(msgId)) else {
      return
    }

    switch msg {

    case .serverReady:
      self.establishNvimConnection()

    case .nvimReady:
      self.isInitErrorPresent = data?.asArray(ofType: Bool.self, count: 1)?[0] ?? false
      self.nvimReadyCondition.lock()
      self.isNvimReady = true
      defer {
        self.nvimReadyCondition.signal()
        self.nvimReadyCondition.unlock()
      }

    case .resize:
      guard let values = data?.asArray(ofType: Int.self, count: 2) else {
        return
      }

      self.nvimView?.resize(width: values[0], height: values[1])


    case .clear:
      self.nvimView?.clear()

    case .eolClear:
      self.nvimView?.eolClear()

    case .setMenu:
      self.nvimView?.updateMenu()

    case .busyStart:
      self.nvimView?.busyStart()

    case .busyStop:
      self.nvimView?.busyStop()

    case .mouseOn:
      self.nvimView?.mouseOn()

    case .mouseOff:
      self.nvimView?.mouseOff()

    case .modeChange:
      guard let values = data?.asArray(ofType: CursorModeShape.self, count: 1) else {
        return
      }

      self.nvimView?.modeChange(values[0])

    case .setScrollRegion:
      guard let values = data?.asArray(ofType: Int.self, count: 4) else {
        return
      }

      self.nvimView?.setScrollRegion(top: values[0], bottom: values[1], left: values[2], right: values[3])

    case .scroll:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.nvimView?.scroll(values[0])

    case .unmark:
      guard let values = data?.asArray(ofType: Int.self, count: 2) else {
        return
      }

      self.nvimView?.unmark(row: values[0], column: values[1])

    case .bell:
      self.nvimView?.bell()

    case .visualBell:
      self.nvimView?.visualBell()

    case .flush:
      guard let d = data, let renderData = NSKeyedUnarchiver.unarchiveObject(with: d) as? [Data] else {
        return
      }

      self.nvimView?.flush(renderData)

    case .setForeground:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.nvimView?.update(foreground: values[0])

    case .setBackground:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.nvimView?.update(background: values[0])

    case .setSpecial:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.nvimView?.update(special: values[0])

    case .setTitle:
      guard let d = data, let title = String(data: d, encoding: .utf8) else {
        return
      }

      self.nvimView?.set(title: title)

    case .setIcon:
      guard let d = data, let icon = String(data: d, encoding: .utf8) else {
        return
      }

      self.nvimView?.set(icon: icon)

    case .stop:
      self.nvimView?.stop()

    case .dirtyStatusChanged:
      guard let values = data?.asArray(ofType: Bool.self, count: 1) else {
        return
      }

      self.nvimView?.set(dirty: values[0])

    case .cwdChanged:
      guard let d = data, let cwd = String(data: d, encoding: .utf8) else {
        return
      }

      self.nvimView?.cwdChanged(cwd)


    case .colorSchemeChanged:
      guard let values = data?.asArray(ofType: Int.self, count: 5) else {
        return
      }

      self.nvimView?.colorSchemeChanged(values)

    case .autoCommandEvent:
      if data?.count == 2 * MemoryLayout<Int>.stride {
        guard let values = data?.asArray(ofType: Int.self, count: 2),
              let cmd = NvimAutoCommandEvent(rawValue: values[0])
          else {
          return
        }

        self.nvimView?.autoCommandEvent(cmd, bufferHandle: values[1])

      } else {
        guard let values = data?.asArray(ofType: NvimAutoCommandEvent.self, count: 1) else {
          return
        }

        self.nvimView?.autoCommandEvent(values[0], bufferHandle: -1)
      }

    case .debug1:
      break

    }

    return
  }

  private func closePorts() {
    CFRunLoopStop(self.localServerRunLoop)
    self.localServerThread?.cancel()

    if CFMessagePortIsValid(self.remoteServerPort) {
      CFMessagePortInvalidate(self.remoteServerPort)
    }
    self.remoteServerPort = nil

    if CFMessagePortIsValid(self.localServerPort) {
      CFMessagePortInvalidate(self.localServerPort)
    }
    self.localServerPort = nil
  }

  private func establishNvimConnection() {
    self.remoteServerPort = CFMessagePortCreateRemote(kCFAllocatorDefault, self.remoteServerName.cfStr)
    self.sendMessage(msgId: .agentReady, data: [self.initialWidth, self.initialHeight].data())
  }

  /// Does not wait for reply.
  private func sendMessage(msgId: NvimBridgeMsgId, data: Data?) {
    if self.isNvimQuitting {
      self.logger.info("NvimServer is quitting, but trying to send msg: \(msgId).")
      return
    }

    if self.remoteServerPort == nil {
      self.logger.info("Remote server port is nil, but trying to send msg: \(msgId).")
      return
    }

    let responseCode = CFMessagePortSendRequest(self.remoteServerPort,
                                                Int32(msgId.rawValue),
                                                data as NSData?,
                                                timeout,
                                                timeout,
                                                nil,
                                                nil)

    if self.isNvimQuitting {
      return
    }

    if responseCode != kCFMessagePortSuccess {
      let msg = "Remote server responded with \(name(of: responseCode)) for msg \(msgId)."

      self.logger.error(msg)
      if !self.isNvimQuitting {
        self.nvimView?.ipcBecameInvalid(msg)
      }
    }
  }

  private func forceExitNvimServer() {
    self.nvimServerProc?.interrupt()
    self.nvimServerProc?.terminate()
  }

  private func launchNvimUsingLoginShell() {
    let selfEnv = ProcessInfo.processInfo.environment

    let shellPath = URL(fileURLWithPath: selfEnv["SHELL"] ?? "/bin/bash")
    let shellName = shellPath.lastPathComponent
    var shellArgs = [String]()
    if shellName != "tcsh" {
      // tcsh does not like the -l option
      shellArgs.append("-l")
    }
    if self.useInteractiveZsh && shellName == "zsh" {
      shellArgs.append("-i")
    }

    let inputPipe = Pipe()
    self.nvimServerProc = Process()

    let listenAddress = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vimr_\(self.uuid).sock")
    var env = selfEnv
    env["NVIM_LISTEN_ADDRESS"] = listenAddress.path

    self.nvimServerProc?.environment = env
    self.nvimServerProc?.standardInput = inputPipe
    self.nvimServerProc?.currentDirectoryPath = self.cwd.path
    self.nvimServerProc?.launchPath = shellPath.path
    self.nvimServerProc?.arguments = shellArgs
    self.nvimServerProc?.launch()

    nvimArgs.append("--headless")
    let cmd = "exec '\(self.nvimServerExecutablePath())' '\(self.localServerName)' '\(self.remoteServerName)' "
      .appending(self.nvimArgs.map { "'\($0)'" }.joined(separator: " "))

    self.logger.debug(cmd)

    let writeHandle = inputPipe.fileHandleForWriting
    guard let cmdData = cmd.data(using: .utf8) else {
      preconditionFailure("Could not get Data from the string '\(cmd)'")
    }
    writeHandle.write(cmdData)
    writeHandle.closeFile()
  }

  private func nvimServerExecutablePath() -> String {
    guard let plugInsPath = Bundle(for: UiBridge.self).builtInPlugInsPath else {
      preconditionFailure("NvimServer not available!")
    }

    return URL(fileURLWithPath: plugInsPath).appendingPathComponent("NvimServer").path
  }

  private func runLocalServer() {
    var localCtx = CFMessagePortContext(version: 0,
                                        info: &self.messageHandler,
                                        retain: nil,
                                        release: nil,
                                        copyDescription: nil)

    self.localServerPort = CFMessagePortCreateLocal(
      kCFAllocatorDefault,
      self.localServerName.cfStr,
      { _, msgid, data, info in
        return info?
          .load(as: MessageHandler.self)
          .handleMessage(msgId: msgid, data: data)
      },
      &localCtx,
      nil // FIXME
    )

    self.localServerRunLoop = CFRunLoopGetCurrent()
    let runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, self.localServerPort, 0)
    CFRunLoopAddSource(self.localServerRunLoop, runLoopSrc, .defaultMode)
    CFRunLoopRun()
  }

  private let logger = LogContext.fileLogger(as: UiBridge.self, with: URL(fileURLWithPath: "/tmp/nvv-bridge.log"))

  private let uuid: String

  private let useInteractiveZsh: Bool
  private let cwd: URL
  private var nvimArgs: [String]

  private var remoteServerPort: CFMessagePort?

  private var localServerPort: CFMessagePort?
  private var localServerThread: Thread?
  private var localServerRunLoop: CFRunLoop?

  private var nvimServerProc: Process?

  private var isNvimReady = false
  private let nvimReadyCondition = NSCondition()
  private var isInitErrorPresent = false

  private var initialWidth = 40
  private var initialHeight = 20

  private var messageHandler: MessageHandler

  private var localServerName: String {
    return "com.qvacua.vimr.\(self.uuid)"
  }

  private var remoteServerName: String {
    return "com.qvacua.vimr.neovim-server.\(self.uuid)"
  }
}

private class MessageHandler {

  fileprivate weak var bridge: UiBridge?

  fileprivate func handleMessage(msgId: Int32, data: CFData?) -> Unmanaged<CFData>? {
    self.bridge?.handleMessage(msgId: msgId, data: data?.data)
    return nil
  }
}

private let timeout = CFTimeInterval(5)

private extension CFData {

  var data: Data {
    return self as NSData as Data
  }
}

private extension String {

  var cfStr: CFString {
    return self as NSString
  }
}

private extension Data {

  func asArray<T>(ofType: T.Type, count: Int) -> [T]? {
    guard (self.count / MemoryLayout<T>.stride) <= count else {
      return nil
    }

    return self.withUnsafeBytes { (p: UnsafePointer<T>) in Array(UnsafeBufferPointer(start: p, count: count)) }
  }
}

private extension Array {

  func data() -> Data {
    return self.withUnsafeBytes { pointer in
      if let baseAddr = pointer.baseAddress {
        return Data(bytes: baseAddr, count: pointer.count)
      }

      let newPointer = UnsafeMutablePointer<Element>.allocate(capacity: self.count)
      for (index, element) in self.enumerated() {
        newPointer[index] = element
      }
      return Data(bytesNoCopy: newPointer, count: self.count, deallocator: .free)
    }
  }
}

private func name(of errorCode: Int32) -> String {
  switch errorCode {
  // @formatter:off
  case kCFMessagePortSendTimeout:        return "kCFMessagePortSendTimeout"
  case kCFMessagePortReceiveTimeout:     return "kCFMessagePortReceiveTimeout"
  case kCFMessagePortIsInvalid:          return "kCFMessagePortIsInvalid"
  case kCFMessagePortTransportError:     return "kCFMessagePortTransportError"
  case kCFMessagePortBecameInvalidError: return "kCFMessagePortBecameInvalidError"
  default:                               return "unknown error"
  // @formatter:on
  }
}
