/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import Foundation
import MessagePack
import NvimServerTypes
import os
import RxPack
import RxSwift

protocol UiBridgeConsumer: AnyObject {
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
  func event(_ value: MessagePackValue)
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

    self.usesCustomTabBar = config.usesCustomTabBar
    self.usesInteractiveZsh = config.useInteractiveZsh
    self.nvimArgs = config.nvimArgs ?? []
    self.cwd = config.cwd

    if let envDict = config.envDict {
      self.envDict = envDict
      self.log.debug("Using ENVs from vimr: \(envDict)")
    } else {
      let selfEnv = ProcessInfo.processInfo.environment
      let shellUrl = URL(fileURLWithPath: selfEnv["SHELL"] ?? "/bin/bash")
      self.log.debug("Using SHELL: \(shellUrl)")
      let interactiveMode = shellUrl.lastPathComponent == "zsh" && !config
        .useInteractiveZsh ? false : true
      self.envDict = ProcessUtils.envVars(of: shellUrl, usingInteractiveMode: interactiveMode)
      self.log.debug("Using ENVs from login shell: \(self.envDict)")
    }

    self.scheduler = SerialDispatchQueueScheduler(
      queue: self.queue,
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
        self.launchNvimUsingLoginShell()

        // This will be completed in .nvimReady branch of handleMessage()
        return Disposables.create()
      })
      .timeout(.seconds(timeout), scheduler: self.scheduler)
  }

  func deleteCharacters(_ count: Int, andInputEscapedString string: String) -> Completable {
    guard let strData = string.data(using: .utf8) else { return .empty() }

    var data = Data(capacity: MemoryLayout<Int>.size + strData.count)

    var c = count
    withUnsafeBytes(of: &c) { data.append(contentsOf: $0) }
    data.append(strData)

    return self.sendMessage(msgId: .deleteInput, data: data)
  }

  func resize(width: Int, height: Int) -> Completable {
    self.sendMessage(msgId: .resize, data: [width, height].data())
  }

  func notifyReadinessForRpcEvents() -> Completable {
    self.sendMessage(msgId: .readyForRpcEvents, data: nil)
  }

  func focusGained(_ gained: Bool) -> Completable {
    self.sendMessage(msgId: .focusGained, data: [gained].data())
  }

  func scroll(horizontal: Int, vertical: Int, at position: Position) -> Completable {
    self.sendMessage(
      msgId: .scroll,
      data: [horizontal, vertical, position.row, position.column].data()
    )
  }

  func quit() -> Completable {
    self.quit {
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

  func debug() -> Completable { self.sendMessage(msgId: .debug1, data: nil) }

  private func handleMessage(msgId: Int32, data: Data?) {
    guard let msg = NvimServerMsgId(rawValue: Int(msgId)) else { return }

    switch msg {
    case .serverReady:
      self
        .establishNvimConnection()
        .subscribe(onError: { [weak self] error in self?.consumer?.ipcBecameInvalid(error) })
        .disposed(by: self.disposeBag)

    case .nvimReady:
      self.runLocalServerAndNvimCompletable?(.completed)
      self.runLocalServerAndNvimCompletable = nil

      let isInitErrorPresent = MessagePackUtils
        .value(from: data, conversion: { $0.boolValue }) ?? false
      if isInitErrorPresent { self.consumer?.initVimError() }

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

    case .event:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.consumer?.event(v)

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
    self.client
      .stop()
      .andThen(self.server.stop())
  }

  private func quit(using body: @escaping () -> Void) -> Completable {
    self
      .closePorts()
      .andThen(Completable.create { completable in
        body()

        completable(.completed)
        return Disposables.create()
      })
  }

  private func establishNvimConnection() -> Completable {
    self.client
      .connect(to: self.remoteServerName)
      .andThen(
        self
          .sendMessage(msgId: .agentReady, data: [self.initialWidth, self.initialHeight].data())
      )
  }

  private func sendMessage(msgId: NvimBridgeMsgId, data: Data?) -> Completable {
    self.client
      .send(msgid: Int32(msgId.rawValue), data: data, expectsReply: false)
      .asCompletable()
  }

  private func forceExitNvimServer() {
    self.nvimServerProc?.interrupt()
    self.nvimServerProc?.terminate()
  }

  private func launchNvimUsingLoginShell() {
    var nvimCmd = [
      // We know that NvimServer is there.
      Bundle.module.url(forResource: "NvimServer", withExtension: nil)!.path,
      self.localServerName,
      self.remoteServerName,
      self.usesCustomTabBar ? "1" : "0",
      "--headless",
    ] + self.nvimArgs

    let listenAddress = FileManager.default.temporaryDirectory
      .appendingPathComponent("vimr_\(self.uuid).sock")
    var nvimEnv = [
      // We know that runtime is there.
      "VIMRUNTIME": Bundle.module.url(forResource: "runtime", withExtension: nil)!.path,
      "NVIM_LISTEN_ADDRESS": listenAddress.path,
    ]

    self.nvimServerProc = ProcessUtils.execProcessViaLoginShell(
      cmd: nvimCmd.map { "'\($0)'" }.joined(separator: " "),
      cwd: self.cwd,
      envs: nvimEnv,
      interactive: self.interactive(for: ProcessUtils.loginShell()),
      qos: .userInteractive
    )
  }

  private func interactive(for shell: URL) -> Bool {
    if shell.lastPathComponent == "zsh" { return self.usesInteractiveZsh }
    return true
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.bridge)

  private let uuid: UUID

  private let usesCustomTabBar: Bool
  private let usesInteractiveZsh: Bool
  private let cwd: URL
  private let nvimArgs: [String]
  private let envDict: [String: String]

  private let server = RxMessagePortServer(queueQos: .userInteractive)
  private let client = RxMessagePortClient(queueQos: .userInteractive)

  private var nvimServerProc: Process?

  private var initialWidth = 40
  private var initialHeight = 20

  private var runLocalServerAndNvimCompletable: Completable.CompletableObserver?

  private let scheduler: SerialDispatchQueueScheduler
  private let queue = DispatchQueue(
    label: String(reflecting: UiBridge.self),
    qos: .userInitiated,
    target: .global(qos: .userInitiated)
  )

  private let disposeBag = DisposeBag()

  private var localServerName: String { "com.qvacua.NvimView.\(self.uuid)" }
  private var remoteServerName: String { "com.qvacua.NvimView.NvimServer.\(self.uuid)" }
}

private let timeout = 5
