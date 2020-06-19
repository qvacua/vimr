/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift
import MessagePack
import os

protocol UiBridgeConsumer: class {

  func initVimError()
  func resize(_ value: MessagePackValue)
  func clear()
  func modeChange(_ value: MessagePackValue)
  func modeInfoSet(_ value: MessagePackValue)
  func flush(_ renderData: [MessagePackValue])
  func setTitle(with value: MessagePackValue)
  func stop()
  func autoCommandEvent(_ value: MessagePackValue)
  func ipcBecameInvalid(_ error: Swift.Error)
  func bell()
  func cwdChanged(_ value: MessagePackValue)
  func colorSchemeChanged(_ value: MessagePackValue)
  func defaultColorsChanged(_ value: MessagePackValue)
  func optionSet(_ value: MessagePackValue)
  func setDirty(with value: MessagePackValue)
  func rpcEventSubscribed()
  func bridgeHasFatalError(_ value: MessagePackValue?)
  func setAttr(with value: MessagePackValue)
  func updateMenu()
  func busyStart()
  func busyStop()
  func mouseOn()
  func mouseOff()
  func visualBell()
  func suspend()
}

class UiBridge {

  weak var consumer: UiBridgeConsumer?

  init(uuid: UUID, config: NvimView.Config) {
    self.uuid = uuid

    self.useInteractiveZsh = config.useInteractiveZsh
    self.nvimArgs = config.nvimArgs ?? []
    self.cwd = config.cwd

    if let envDict = config.envDict {
      self.envDict = envDict
      self.log.debug("Using ENVs from vimr: \(envDict)")
    } else {
      let selfEnv = ProcessInfo.processInfo.environment
      let shellUrl = URL(fileURLWithPath: selfEnv["SHELL"] ?? "/bin/bash")
      self.log.debug("Using SHELL: \(shellUrl)")
      let interactiveMode = shellUrl.lastPathComponent == "zsh" && !config.useInteractiveZsh ? false : true
      self.envDict = ProcessUtils.envVars(of: shellUrl, usingInteractiveMode: interactiveMode)
      self.log.debug("Using ENVs from login shell: \(self.envDict)")
    }

    self.scheduler = SerialDispatchQueueScheduler(
      queue: queue,
      internalSerialQueueName: String(reflecting: UiBridge.self)
    )

    self.server.stream
      .subscribe(onNext: { [weak self] message in
        self?.handleMessage(msgId: message.msgid, data: message.data)
      }, onError: { [weak self] error in
        self?.log.error("There was an error on the local message port server: \(error)")
        self?.consumer?.ipcBecameInvalid(error)
      })
      .disposed(by: self.disposeBag)
  }

  func runLocalServerAndNvim(width: Int, height: Int) -> Completable {
    self.initialWidth = width
    self.initialHeight = height

    return self.server
      .run(as: self.localServerName)
      .andThen(Completable.create { completable in
        self.runLocalServerAndNvimCompletable = completable
        self.launchNvimUsingLoginShellEnv()

        // This will be completed in .nvimReady branch of handleMessage()
        return Disposables.create()
      })
      .timeout(.seconds(timeout), scheduler: self.scheduler)
  }

  func deleteCharacters(_ count: Int, andInputEscapedString string: String)
      -> Completable {
    guard let strData = string.data(using: .utf8) else {
      return .empty()
    }

    var data = Data(capacity: MemoryLayout<Int>.size + strData.count)

    var c = count
    data.append(UnsafeBufferPointer(start: &c, count: 1))
    data.append(strData)

    return self.sendMessage(msgId: .deleteInput, data: data)
  }

  func resize(width: Int, height: Int) -> Completable {
    return self.sendMessage(msgId: .resize, data: [width, height].data())
  }

  func notifyReadinessForRpcEvents() -> Completable {
    return self.sendMessage(msgId: .readyForRpcEvents, data: nil)
  }

  func focusGained(_ gained: Bool) -> Completable {
    return self.sendMessage(msgId: .focusGained, data: [gained].data())
  }

  func scroll(horizontal: Int, vertical: Int, at position: Position) -> Completable {
    return self.sendMessage(msgId: .scroll, data: [horizontal, vertical, position.row, position.column].data())
  }

  func quit() -> Completable {
    return self.quit {
      self.nvimServerProc?.waitUntilExit()
      self.log.info("NvimServer \(self.uuid) exited successfully.")
    }
  }

  func forceQuit() -> Completable {
    self.log.fault("Force-exiting NvimServer \(self.uuid).")

    return self.quit {
      self.forceExitNvimServer()
      self.log.fault("NvimServer \(self.uuid) was forcefully exited.")
    }
  }

  func debug() -> Completable {
    return self.sendMessage(msgId: .debug1, data: nil)
  }

  private func handleMessage(msgId: Int32, data: Data?) {
    guard let msg = NvimServerMsgId(rawValue: Int(msgId)) else {
      return
    }

    switch msg {

    case .serverReady:
      self
        .establishNvimConnection()
        .subscribe(onError: { [weak self] error in
          self?.consumer?.ipcBecameInvalid(error)
        })
        .disposed(by: self.disposeBag)

    case .nvimReady:
      self.runLocalServerAndNvimCompletable?(.completed)
      self.runLocalServerAndNvimCompletable = nil

      let isInitErrorPresent = MessagePackUtils.value(from: data, conversion: { $0.boolValue }) ?? false
      if isInitErrorPresent {
        self.consumer?.initVimError()
      }

    case .resize:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.resize(v)

    case .clear:
      self.consumer?.clear()

    case .setMenu:
      self.consumer?.updateMenu()

    case .busyStart:
      self.consumer?.busyStart()

    case .busyStop:
      self.consumer?.busyStop()

    case .modeChange:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.modeChange(v)

    case .modeInfoSet:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.modeInfoSet(v)

    case .bell:
      self.consumer?.bell()

    case .visualBell:
      self.consumer?.visualBell()

    case .flush:
      guard let d = data, let v = (try? unpackAll(d)) else { return }
      self.consumer?.flush(v)

    case .setTitle:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.setTitle(with: v)

    case .stop:
      self.consumer?.stop()

    case .dirtyStatusChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.setDirty(with: v)

    case .cwdChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.cwdChanged(v)

    case .defaultColorsChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.defaultColorsChanged(v)

    case .colorSchemeChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.colorSchemeChanged(v)

    case .optionSet:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.optionSet(v)

    case .autoCommandEvent:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.autoCommandEvent(v)

    case .debug1:
      break

    case .highlightAttrs:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.setAttr(with: v)

    case .rpcEventSubscribed:
      self.consumer?.rpcEventSubscribed()

    case .fatalError:
      self.consumer?.bridgeHasFatalError(MessagePackUtils.value(from: data))

    @unknown default:
      self.log.error("Unkonwn msg type from NvimServer")

    }
  }

  private func closePorts() -> Completable {
    return self.client
      .stop()
      .andThen(self.server.stop())
  }

  private func quit(using body: @escaping () -> Void) -> Completable {
    return self
      .closePorts()
      .andThen(Completable.create { completable in
        body()

        completable(.completed)
        return Disposables.create()
      })
  }

  private func establishNvimConnection() -> Completable {
    return self.client
      .connect(to: self.remoteServerName)
      .andThen(self.sendMessage(msgId: .agentReady, data: [self.initialWidth, self.initialHeight].data()))
  }

  private func sendMessage(msgId: NvimBridgeMsgId, data: Data?) -> Completable {
    return self.client
      .send(msgid: Int32(msgId.rawValue), data: data, expectsReply: false)
      .asCompletable()
  }

  private func forceExitNvimServer() {
    self.nvimServerProc?.interrupt()
    self.nvimServerProc?.terminate()
  }

  private func launchNvimUsingLoginShellEnv() {
    let listenAddress = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vimr_\(self.uuid).sock")
    var env = self.envDict
    env["NVIM_LISTEN_ADDRESS"] = listenAddress.path

    self.log.debug("Socket: \(listenAddress.path)")

    let outPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()
    process.environment = env
    process.standardError = errorPipe
    process.standardOutput = outPipe
    process.currentDirectoryPath = self.cwd.path
    process.launchPath = self.nvimServerExecutablePath()
    process.arguments = [self.localServerName, self.remoteServerName] + ["--headless"] + self.nvimArgs
    self.log.debug(
      "Launching NvimServer with args: \(String(describing: process.arguments))"
    )
    process.launch()

    self.nvimServerProc = process
  }

  private func nvimServerExecutablePath() -> String {
    Bundle(for: UiBridge.self)
      .bundleURL
      .appendingPathComponent("Versions")
      .appendingPathComponent("A")
      .appendingPathComponent("NvimServer")
      .path
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.bridge)

  private let uuid: UUID

  private let useInteractiveZsh: Bool
  private let cwd: URL
  private let nvimArgs: [String]
  private let envDict: [String: String]

  private let server = RxMessagePortServer()
  private let client = RxMessagePortClient()

  private var nvimServerProc: Process?

  private var initialWidth = 40
  private var initialHeight = 20

  private var runLocalServerAndNvimCompletable: Completable.CompletableObserver?

  private let scheduler: SerialDispatchQueueScheduler
  private let queue = DispatchQueue(
    label: String(reflecting: UiBridge.self),
    qos: .userInitiated
  )

  private let disposeBag = DisposeBag()

  private var localServerName: String {
    return "com.qvacua.NvimView.\(self.uuid)"
  }

  private var remoteServerName: String {
    return "com.qvacua.NvimView.NvimServer.\(self.uuid)"
  }
}

private let timeout = 5
