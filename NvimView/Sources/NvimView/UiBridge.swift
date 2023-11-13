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

    self.scheduler = SerialDispatchQueueScheduler(
      queue: self.queue,
      internalSerialQueueName: String(reflecting: UiBridge.self)
    )
  }

  func runLocalServerAndNvim(width: Int, height: Int) {
    self.initialWidth = width
    self.initialHeight = height

    self.launchNvimUsingLoginShellEnv()
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

  private func launchNvimUsingLoginShellEnv() {
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
      return
    }

    self.nvimServerProc = process
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

  var listenAddress: String {
    URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("vimr_\(self.uuid).sock").path
  }
}

private let timeout = 5
