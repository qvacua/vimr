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
    case resize(width: Int, height: Int)
    case clear
    case setMenu
    case busyStart
    case busyStop
    case mouseOn
    case mouseOff
    case modeChange(CursorModeShape)
    case setScrollRegion(top: Int, bottom: Int, left: Int, right: Int)
    case scroll(Int)
    case unmark(row: Int, column: Int)
    case bell
    case visualBell
    case flush([MessagePackValue])
    case setForeground(Int)
    case setBackground(Int)
    case setSpecial(Int)
    case setTitle(String)
    case setIcon(String)
    case stop
    case dirtyStatusChanged(Bool)
    case cwdChanged(String)
    case colorSchemeChanged([Int])
    case optionSet(key: String, value: MessagePackValue)
    case defaultColorsChanged([Int])
    case autoCommandEvent(autocmd: NvimAutoCommandEvent, bufferHandle: Int)
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

  func vimInputMarkedText(_ markedText: String) -> Completable {
    return self.sendMessage(msgId: .inputMarked, data: markedText.data(using: .utf8))
  }

  func deleteCharacters(_ count: Int) -> Completable {
    return self.sendMessage(msgId: .delete, data: [count].data())
  }

  func resize(width: Int, height: Int) -> Completable {
    return self.sendMessage(msgId: .resize, data: [width, height].data())
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

      let isInitErrorPresent = value(from: data, conversion: { $0.boolValue }) ?? false
      if isInitErrorPresent {
        self.streamSubject.onNext(.initVimError)
      }

    case .resize:
      guard let values = array(from: data, ofSize: 2, conversion: { v -> Int? in
        guard let i64 = v.integerValue else { return nil }
        return Int(i64)
      }) else {
        return
      }
      self.streamSubject.onNext(.resize(width: values[0], height: values[1]))

    case .clear:
      self.streamSubject.onNext(.clear)

    case .setMenu:
      self.streamSubject.onNext(.setMenu)

    case .busyStart:
      self.streamSubject.onNext(.busyStart)

    case .busyStop:
      self.streamSubject.onNext(.busyStop)

    case .mouseOn:
      self.streamSubject.onNext(.mouseOn)

    case .mouseOff:
      self.streamSubject.onNext(.mouseOff)

    case .modeChange:
      guard let value = value(from: data, conversion: { v -> CursorModeShape? in
        guard let i64 = v.integerValue else { return nil }
        return CursorModeShape(rawValue: UInt(i64))
      }) else {
        return
      }

      self.streamSubject.onNext(.modeChange(value))

    case .setScrollRegion:
      guard let values = array(from: data, ofSize: 4, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.setScrollRegion(top: values[0], bottom: values[1], left: values[2], right: values[3]))

    case .scroll:
      guard let value = value(from: data, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.scroll(value))

    case .unmark:
      guard let values = array(from: data, ofSize: 2, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.unmark(row: values[0], column: values[1]))

    case .bell:
      self.streamSubject.onNext(.bell)

    case .visualBell:
      self.streamSubject.onNext(.visualBell)

    case .flush:
      guard let d = data, let renderData = try? unpackAll(d) else {
        return
      }

      self.streamSubject.onNext(.flush(renderData))

    case .setForeground:
      guard let value = value(from: data, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.setForeground(value))

    case .setBackground:
      guard let value = value(from: data, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.setBackground(value))

    case .setSpecial:
      guard let value = value(from: data, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.setSpecial(value))

    case .setTitle:
      guard let title = value(from: data, conversion: { $0.stringValue }) else {
        return
      }

      self.streamSubject.onNext(.setTitle(title))

    case .setIcon:
      guard let icon = value(from: data, conversion: { $0.stringValue }) else {
        return
      }

      self.streamSubject.onNext(.setIcon(icon))

    case .stop:
      self.streamSubject.onNext(.stop)

    case .dirtyStatusChanged:
      guard let value = value(from: data, conversion: { $0.boolValue }) else {
        return
      }

      self.streamSubject.onNext(.dirtyStatusChanged(value))

    case .cwdChanged:
      guard let cwd = value(from: data, conversion: { $0.stringValue }) else {
        return
      }

      self.streamSubject.onNext(.cwdChanged(cwd))

    case .defaultColorsChanged:
      guard let values = array(from: data, ofSize: 3, conversion: { $0.intValue }) else {
        return
      }

      self.streamSubject.onNext(.defaultColorsChanged(values))

    case .colorSchemeChanged:
      guard let d = data, let rawValues = (try? unpack(d))?.value.arrayValue else {
        return
      }

      let values = rawValues.compactMap { $0.integerValue }.map { Int($0) }
      self.streamSubject.onNext(.colorSchemeChanged(values))

    case .optionSet:
      guard let d = data,
            let dict = (try? unpack(d))?.value.dictionaryValue,
            let key = dict.keys.first?.stringValue,
            let value = dict.values.first
        else {
        return
      }

      self.logger.debug("option set: \(key) -> \(value)")
      self.streamSubject.onNext(.optionSet(key: key, value: value))

    case .autoCommandEvent:
      guard let values = array(from: data, ofSize: 2, conversion: { $0.intValue }),
            let cmd = NvimAutoCommandEvent(rawValue: values[0]) else { return }

      self.streamSubject.onNext(.autoCommandEvent(autocmd: cmd, bufferHandle: values[1]))

    case .debug1:
      self.streamSubject.onNext(.debug1)

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

    let outPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()
    process.environment = env
    process.standardError = errorPipe
    process.standardOutput = outPipe
    process.currentDirectoryPath = self.cwd.path
    process.launchPath = self.nvimServerExecutablePath()
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

private func value<T>(from data: Data?, conversion: (MessagePackValue) -> T?) -> T? {
  guard let d = data, let value = (try? unpack(d))?.value else {
    return nil
  }

  return conversion(value)
}

private func array<T>(from data: Data?, ofSize size: Int, conversion: (MessagePackValue) -> T?) -> [T]? {
  guard let d = data, let array = (try? unpack(d))?.value.arrayValue else {
    return nil
  }

  guard array.count == size else {
    return nil
  }

  return array.compactMap(conversion)
}
