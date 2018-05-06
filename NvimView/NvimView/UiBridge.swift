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
    case flush([Data])
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
        self.launchNvimUsingLoginShell()

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

      let isInitErrorPresent = data?.asArray(ofType: Bool.self, count: 1)?[0] ?? false
      if isInitErrorPresent {
        self.streamSubject.onNext(.initVimError)
      }

    case .resize:
      guard let values = data?.asArray(ofType: Int.self, count: 2) else {
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
      guard let values = data?.asArray(ofType: CursorModeShape.self, count: 1) else {
        return
      }

      self.streamSubject.onNext(.modeChange(values[0]))

    case .setScrollRegion:
      guard let values = data?.asArray(ofType: Int.self, count: 4) else {
        return
      }

      self.streamSubject.onNext(.setScrollRegion(top: values[0], bottom: values[1], left: values[2], right: values[3]))

    case .scroll:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.streamSubject.onNext(.scroll(values[0]))

    case .unmark:
      guard let values = data?.asArray(ofType: Int.self, count: 2) else {
        return
      }

      self.streamSubject.onNext(.unmark(row: values[0], column: values[1]))

    case .bell:
      self.streamSubject.onNext(.bell)

    case .visualBell:
      self.streamSubject.onNext(.visualBell)

    case .flush:
      guard let d = data, let renderData = NSKeyedUnarchiver.unarchiveObject(with: d) as? [Data] else {
        return
      }

      self.streamSubject.onNext(.flush(renderData))

    case .setForeground:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.streamSubject.onNext(.setForeground(values[0]))

    case .setBackground:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.streamSubject.onNext(.setBackground(values[0]))

    case .setSpecial:
      guard let values = data?.asArray(ofType: Int.self, count: 1) else {
        return
      }

      self.streamSubject.onNext(.setSpecial(values[0]))

    case .setTitle:
      guard let d = data, let title = String(data: d, encoding: .utf8) else {
        return
      }

      self.streamSubject.onNext(.setTitle(title))

    case .setIcon:
      guard let d = data, let icon = String(data: d, encoding: .utf8) else {
        return
      }

      self.streamSubject.onNext(.setIcon(icon))

    case .stop:
      self.streamSubject.onNext(.stop)

    case .dirtyStatusChanged:
      guard let values = data?.asArray(ofType: Bool.self, count: 1) else {
        return
      }

      self.streamSubject.onNext(.dirtyStatusChanged(values[0]))

    case .cwdChanged:
      guard let d = data, let cwd = String(data: d, encoding: .utf8) else {
        return
      }

      self.streamSubject.onNext(.cwdChanged(cwd))

    case .defaultColorsChanged:
      guard let values = data?.asArray(ofType: Int.self, count: 3) else {
        return
      }

      self.streamSubject.onNext(.defaultColorsChanged(values))

    case .colorSchemeChanged:
      guard let values = data?.asArray(ofType: Int.self, count: 5) else {
        return
      }

      self.streamSubject.onNext(.colorSchemeChanged(values))

    case .optionSet:
      guard let d = data,
            let dict = NSKeyedUnarchiver.unarchiveObject(with: d) as? Dictionary<String, Data>,
            let key = dict.keys.first,
            let valueData = dict[key],
            let values = try? unpackAll(valueData),
            let value = values.first
          else {
        return
      }

      self.logger.debug("\(key) -> \(value)")
      self.streamSubject.onNext(.optionSet(key: key, value: value))

    case .autoCommandEvent:
      if data?.count == 2 * MemoryLayout<Int>.stride {
        guard let values = data?.asArray(ofType: Int.self, count: 2),
              let cmd = NvimAutoCommandEvent(rawValue: values[0])
          else {
          return
        }

        self.streamSubject.onNext(.autoCommandEvent(autocmd: cmd, bufferHandle: values[1]))

      } else {
        guard let values = data?.asArray(ofType: NvimAutoCommandEvent.self, count: 1) else {
          return
        }

        self.streamSubject.onNext(.autoCommandEvent(autocmd: values[0], bufferHandle: -1))
      }

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

    let listenAddress = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vimr_\(self.uuid).sock")
    var env = selfEnv
    env["NVIM_LISTEN_ADDRESS"] = listenAddress.path

    let inputPipe = Pipe()
    let process = Process()
    process.environment = env
    process.standardInput = inputPipe
    process.currentDirectoryPath = self.cwd.path
    process.launchPath = shellPath.path
    process.arguments = shellArgs
    process.launch()

    self.nvimServerProc = process

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

  private let logger = LogContext.fileLogger(as: UiBridge.self, with: URL(fileURLWithPath: "/tmp/nvv-bridge.log"))

  private let uuid: String

  private let useInteractiveZsh: Bool
  private let cwd: URL
  private var nvimArgs: [String]

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
