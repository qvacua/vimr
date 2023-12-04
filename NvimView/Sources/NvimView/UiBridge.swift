/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import Foundation
import MessagePack
import os
import RxPack
import RxSwift
import RxNeovim
import RxPack

let kMinAlphaVersion = 0
let kMinMinorVersion = 10
let kMinMajorVersion = 1

final class UiBridge {
  init(uuid: UUID, config: NvimView.Config) {
    self.uuid = uuid

    self.usesInteractiveZsh = config.useInteractiveZsh
    self.nvimBinary = config.nvimBinary
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
  }

  func runLocalServerAndNvim(width: Int, height: Int) throws {
    self.initialWidth = width
    self.initialHeight = height

    try self.launchNvimUsingLoginShellEnv()
  }

  func quit() -> Completable {
    Completable.create { completable in
      self.nvimServerProc?.waitUntilExit()
      self.log.info("NvimServer \(self.uuid) exited successfully.")
      completable(.completed)
      return Disposables.create()
    }
  }

  func forceQuit() -> Completable {
    self.log.fault("Force-exiting NvimServer \(self.uuid).")

    return Completable.create { _ in
      self.forceExitNvimServer()
      self.log.fault("NvimServer \(self.uuid) was forcefully exited.")
      return Disposables.create()
    }
  }

  private func forceExitNvimServer() {
    self.nvimServerProc?.interrupt()
    self.nvimServerProc?.terminate()
  }

  private func launchNvimUsingLoginShellEnv() throws {
    var env = self.envDict
    env["NVIM_LISTEN_ADDRESS"] = self.listenAddress

    self.log.debug("Socket: \(self.listenAddress)")

    let inPipe = Pipe()
    let outPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()
    process.standardInput = inPipe
    process.standardError = errorPipe
    process.standardOutput = outPipe
    process.currentDirectoryPath = self.cwd.path

    if self.nvimBinary != "",
       FileManager.default.fileExists(atPath: self.nvimBinary)
    {
      process.launchPath = self.nvimBinary
    } else {
      // We know that NvimServer is there.
      env["VIMRUNTIME"] = Bundle.module.url(forResource: "runtime", withExtension: nil)!.path
      let launchPath = Bundle.module.url(forResource: "NvimServer", withExtension: nil)!.path
      process.launchPath = launchPath
    }
    process.environment = env

    process
      .arguments =
      ["--embed",
       "--listen",
       self.listenAddress] + self.nvimArgs

    self.log.debug(
      "Launching NvimServer \(String(describing: process.launchPath)) with args: \(String(describing: process.arguments))"
    )
    do {
      try process.run()
    } catch {
      throw RxNeovimApi.Error
        .exception(message: "Could not run neovim process.")
    }

    try self.doInitialVersionCheck(inPipe: inPipe, outPipe: outPipe)

    self.nvimServerProc = process
  }

  private func doInitialVersionCheck(inPipe: Pipe, outPipe: Pipe) throws {

    // Construct Msgpack query for api info
    let packed = pack(
      [
        .uint(RxMsgpackRpc.MessageType.request.rawValue),
        .uint(UInt64(0)),
        .string("nvim_get_api_info"),
        .array([]),
      ]
    )

    try inPipe.fileHandleForWriting.write(contentsOf: packed)

    // Read responses from the pipe back
    var accumulatedData : Data = Data()
    var values : [MessagePackValue] = []
    var remainderData: Data? = nil
    while (true) {
      let data = outPipe.fileHandleForReading.availableData
      if data.count == 0 {
        break
      }
      accumulatedData.append(data)
      
      try (values, remainderData) = RxMsgpackRpc.unpackAllWithReminder(accumulatedData)
      
      if let remainderData { accumulatedData = remainderData }
      else { accumulatedData.count = 0 }
      
      if values.count > 0 {
        break
      }
    }

    // Validate version response
    guard values.count >= 1,
          let firstResponse = values[0].arrayValue,
          firstResponse.count == 4,
          let rawType = firstResponse[0].uint64Value,
          let type = RxMsgpackRpc.MessageType(rawValue: rawType),
          type == RxMsgpackRpc.MessageType.response /* this is a response */,
          let msgId = firstResponse[1].uint64Value,
          msgId == 0 /* no confusion on stream */,
          firstResponse[2] == nil /* no error */,
          let info = firstResponse[3].arrayValue /* response value */,
          info.count == 2,
          let dict = info[1].dictionaryValue,
          let version = dict["version"]?.dictionaryValue,
          let major = version["major"]?.intValue,
          let minor = version["minor"]?.intValue
    else {
      throw RxNeovimApi.Error
        .exception(message: "Could not convert values to api info.")
    }
    guard (major >= kMinAlphaVersion && minor >= kMinMinorVersion) || major >= kMinMajorVersion
    else {
      throw RxNeovimApi.Error
        .exception(message: "Incompatible neovim version.")
    }
  }

  private func interactive(for shell: URL) -> Bool {
    if shell.lastPathComponent == "zsh" { return self.usesInteractiveZsh }
    return true
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.bridge)

  private let uuid: UUID

  private let usesInteractiveZsh: Bool
  private let cwd: URL
  private let nvimArgs: [String]
  private let envDict: [String: String]
  private let nvimBinary: String

  private var nvimServerProc: Process?

  private var initialWidth = 40
  private var initialHeight = 20

  private let disposeBag = DisposeBag()

  var listenAddress: String {
    URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("vimr_\(self.uuid).sock").path
  }
}

private let timeout = 5
