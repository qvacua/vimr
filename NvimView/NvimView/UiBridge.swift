/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxMessagePort
import RxSwift
import MessagePack

class UiBridge {

  enum Message {

    case ready

    case initVimError
    case resize(MessagePackValue)
    case clear
    case setMenu
    case busyStart
    case busyStop
    case mouseOn
    case mouseOff
    case modeChange(MessagePackValue)
    case bell
    case visualBell
    case flush([MessagePackValue])
    case setTitle(MessagePackValue)
    case stop
    case dirtyStatusChanged(MessagePackValue)
    case cwdChanged(MessagePackValue)
    case colorSchemeChanged(MessagePackValue)
    case optionSet(MessagePackValue)
    case defaultColorsChanged(MessagePackValue)
    case autoCommandEvent(MessagePackValue)
    case highlightAttrs(MessagePackValue)
    case rpcEventSubscribed
    case debug1
    case unknown
  }

  enum Error: Swift.Error {

    case launchNvim
    case nvimNotReady
    case nvimQuitting
    case ipc(Swift.Error)
  }

  var stream: Observable<Message> {
    return self.streamSubject.asObservable()
  }

  init(uuid: String, queue: DispatchQueue, config: NvimView.Config) {
    self.uuid = uuid

    self.useInteractiveZsh = config.useInteractiveZsh
    self.nvimArgs = config.nvimArgs ?? []
    self.cwd = config.cwd

    if let envDict = config.envDict {
      self.envDict = envDict
      logger.debug("using envs from vimr: \(envDict)")
    } else {
      let selfEnv = ProcessInfo.processInfo.environment
      let shellUrl = URL(fileURLWithPath: selfEnv["SHELL"] ?? "/bin/bash")
      let interactiveMode = shellUrl.lastPathComponent == "zsh" && !config.useInteractiveZsh ? false : true
      self.envDict = ProcessUtils.envVars(of: shellUrl, usingInteractiveMode: interactiveMode)
      logger.debug("using envs from login shell: \(self.envDict)")
    }

    self.queue = queue
    self.scheduler = SerialDispatchQueueScheduler(queue: queue,
                                                  internalSerialQueueName: String(reflecting: UiBridge.self))
    self.client.queue = self.queue
    self.server.queue = self.queue

    self.server.stream
      .subscribe(onNext: { message in
        self.handleMessage(msgId: message.msgid, data: message.data)
      }, onError: { error in
        self.logger.error("There was an error on the local message port server: \(error)")
        self.streamSubject.onError(Error.ipc(error))
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
      .timeout(timeout, scheduler: self.scheduler)
  }

  func vimInput(_ str: String) -> Completable {
    return self.sendMessage(msgId: .input, data: str.data(using: .utf8))
  }

  func deleteCharacters(_ count: Int, andInputEscapedString string: String)
      -> Completable
  {
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
      self.logger.info("NvimServer \(self.uuid) exited successfully.")
    }
  }

  func forceQuit() -> Completable {
    self.logger.info("Force-exiting NvimServer \(self.uuid).")

    return self.quit {
      self.forceExitNvimServer()
      self.logger.info("NvimServer \(self.uuid) was forcefully exited.")
    }
  }

  func debug() -> Completable {
    return self.sendMessage(msgId: .debug1, data: nil)
  }

  private func handleMessage(msgId: Int32, data: Data?) {
    guard let msg = NvimServerMsgId(rawValue: Int(msgId)) else {
      self.streamSubject.onNext(.unknown)
      return
    }

    switch msg {

    case .serverReady:
      self
        .establishNvimConnection()
        .subscribe(onError: { error in
          self.streamSubject.onError(Error.ipc(error))
        })
        .disposed(by: self.disposeBag)

    case .nvimReady:
      self.runLocalServerAndNvimCompletable?(.completed)
      self.runLocalServerAndNvimCompletable = nil

      self.streamSubject.onNext(.ready)

      let isInitErrorPresent = MessagePackUtils.value(from: data, conversion: { $0.boolValue }) ?? false
      if isInitErrorPresent {
        self.streamSubject.onNext(.initVimError)
      }

    case .resize:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.resize(v))
      break

    case .clear:
      self.streamSubject.onNext(.clear)

    case .setMenu:
      self.streamSubject.onNext(.setMenu)

    case .busyStart:
      self.streamSubject.onNext(.busyStart)

    case .busyStop:
      self.streamSubject.onNext(.busyStop)

    case .modeChange:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.modeChange(v))

    case .bell:
      self.streamSubject.onNext(.bell)

    case .visualBell:
      self.streamSubject.onNext(.visualBell)

    case .flush:
      guard let d = data, let v = (try? unpackAll(d)) else { return }
      self.streamSubject.onNext(.flush(v))

    case .setTitle:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.setTitle(v))

    case .stop:
      self.streamSubject.onNext(.stop)

    case .dirtyStatusChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.dirtyStatusChanged(v))

    case .cwdChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.cwdChanged(v))

    case .defaultColorsChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.defaultColorsChanged(v))

    case .colorSchemeChanged:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.colorSchemeChanged(v))

    case .optionSet:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.optionSet(v))

    case .autoCommandEvent:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.autoCommandEvent(v))

    case .debug1:
      self.streamSubject.onNext(.debug1)

    case .highlightAttrs:
      guard let v = MessagePackUtils.value(from: data) else { return }
      self.streamSubject.onNext(.highlightAttrs(v))

    case .rpcEventSubscribed:
      self.streamSubject.onNext(.rpcEventSubscribed)

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

    stdoutLogger.debug("listen addr: \(listenAddress.path)")

    let outPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()
    process.environment = env
    process.standardError = errorPipe
    process.standardOutput = outPipe
    process.currentDirectoryPath = self.cwd.path
    process.launchPath = self.nvimServerExecutablePath()
    // GH-666: FIXME
//    process.arguments = [self.localServerName, self.remoteServerName] + ["--headless", "/Users/hat/php.php"] + self.nvimArgs
    process.arguments = [self.localServerName, self.remoteServerName] + ["--headless"] + self.nvimArgs
    process.launch()

    self.nvimServerProc = process
  }

  private func nvimServerExecutablePath() -> String {
    guard let plugInsPath = Bundle(for: UiBridge.self).builtInPlugInsPath else {
      preconditionFailure("NvimServer not available!")
    }

    return URL(fileURLWithPath: plugInsPath).appendingPathComponent("NvimServer").path
  }

  private let logger = LogContext.fileLogger(as: UiBridge.self, with: URL(fileURLWithPath: "/tmp/nvv-bridge.log"))

  private let uuid: String

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
  private let queue: DispatchQueue

  private let streamSubject = PublishSubject<Message>()
  private let disposeBag = DisposeBag()

  private var localServerName: String {
    return "com.qvacua.vimr.\(self.uuid)"
  }

  private var remoteServerName: String {
    return "com.qvacua.vimr.neovim-server.\(self.uuid)"
  }
}

private let timeout = CFTimeInterval(5)

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
