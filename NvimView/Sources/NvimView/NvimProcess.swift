/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import Foundation
import MessagePack
import NvimApi
import os

let kMinMajorVersion = 0
let kMinMinorVersion = 10
let kMinPatchVersion = 0

final class NvimProcess {
  var pipeUrl: URL {
    let temp = FileManager.default.temporaryDirectory
    return temp.appending(path: "\(self.uuid).pipe")
  }
  
  init(uuid: UUID, config: NvimView.Config) {
    self.uuid = uuid

    self.usesInteractiveZsh = config.useInteractiveZsh
    self.nvimBinary = config.nvimBinary
    self.nvimArgs = config.nvimArgs ?? []
    self.cwd = config.cwd

    let selfEnv = ProcessInfo.processInfo.environment
    let shellUrl = URL(fileURLWithPath: selfEnv["SHELL"] ?? "/bin/bash")
    dlog.debug("Using SHELL: \(shellUrl)")
    let interactiveMode = shellUrl.lastPathComponent == "zsh" && !config
      .useInteractiveZsh ? false : true
    self.envDict = ProcessUtils.envVars(of: shellUrl, usingInteractiveMode: interactiveMode)
      .merging(config.additionalEnvs) { _, new in new }
    dlog.debug("Using ENVs from login shell: \(self.envDict)")
  }

  func runLocalServerAndNvim(width _: Int, height _: Int) throws -> (Pipe, Pipe, Pipe) {
    try self.launchNvimUsingLoginShellEnv()
  }

  /// Launch nvim with --embed --listen for socket-launch mode.
  /// nvim blocks its event loop until nvim_ui_attach is called on the socket.
  func runLocalServerEmbedSocket() throws {
    try self.launchNvimEmbedSocket()
  }

  func quit() {
    self.nvimServerProc?.waitUntilExit()
    dlog.debug("NvimServer \(self.uuid) exited successfully.")
  }

  func forceQuit() {
    self.logger.fault("Force-exiting NvimServer \(self.uuid).")
    self.forceExitNvimServer()
    self.logger.fault("NvimServer \(self.uuid) was forcefully exited.")
  }

  private func forceExitNvimServer() {
    self.nvimServerProc?.interrupt()
    self.nvimServerProc?.terminate()
  }

  private func launchNvimEmbedSocket() throws {
    var env = self.envDict

    let process = Process()
    // Use a pipe for stdin so nvim doesn't read EOF from /dev/null.
    // With --embed --listen, nvim blocks its event loop waiting for nvim_ui_attach
    // on the socket rather than driving the UI via stdio, so this pipe is never
    // written to — it just keeps stdin open.
    process.standardInput = Pipe()
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    process.currentDirectoryPath = self.cwd.path
    process.qualityOfService = .userInteractive

    if self.nvimBinary != "", FileManager.default.fileExists(atPath: self.nvimBinary) {
      process.launchPath = self.nvimBinary
    } else {
      env["VIMRUNTIME"] = Bundle.module.url(forResource: "runtime", withExtension: nil)!.path
      let launchPath = Bundle.module.url(forResource: "NvimServer", withExtension: nil)!.path
      process.launchPath = launchPath
    }
    process.environment = env
    // --embed --listen: nvim starts without a TUI and blocks its event loop until
    // nvim_ui_attach is called on the socket. This means we don't need to poll for
    // socket creation — connecting and calling nvim_ui_attach is sufficient
    // synchronisation.
    process.arguments = ["--embed", "--listen", self.pipeUrl.path] + self.nvimArgs

    dlog.debug("Servername (socket-launch): \(self.pipeUrl.path)")
    dlog.debug(
      "Launching NvimServer (socket-launch) \(String(describing: process.launchPath)) with args: \(String(describing: process.arguments))"
    )
    do {
      try process.run()
    } catch {
      throw NvimApi.Error.exception(message: "Could not run neovim process (socket-launch).")
    }

    self.nvimServerProc = process
  }

  private func launchNvimUsingLoginShellEnv() throws -> (Pipe, Pipe, Pipe) {
    var env = self.envDict

    let inPipe = Pipe()
    let outPipe = Pipe()
    let errorPipe = Pipe()
    let process = Process()
    process.standardInput = inPipe
    process.standardError = errorPipe
    process.standardOutput = outPipe
    process.currentDirectoryPath = self.cwd.path
    process.qualityOfService = .userInteractive

    if self.nvimBinary != "", FileManager.default.fileExists(atPath: self.nvimBinary) {
      process.launchPath = self.nvimBinary
    } else {
      // We know that NvimServer is there.
      env["VIMRUNTIME"] = Bundle.module.url(forResource: "runtime", withExtension: nil)!.path
      let launchPath = Bundle.module.url(forResource: "NvimServer", withExtension: nil)!.path
      process.launchPath = launchPath
    }
    process.environment = env
    process.arguments = ["--embed", "--listen", self.pipeUrl.path] + self.nvimArgs

    dlog.debug("Servername: \(self.pipeUrl.path)")
    dlog.debug(
      "Launching NvimServer \(String(describing: process.launchPath)) with args: \(String(describing: process.arguments))"
    )
    do {
      try process.run()
    } catch {
      throw NvimApi.Error.exception(message: "Could not run neovim process.")
    }

    self.nvimServerProc = process
    return (inPipe, outPipe, errorPipe)
  }

  private func interactive(for shell: URL) -> Bool {
    if shell.lastPathComponent == "zsh" { return self.usesInteractiveZsh }
    return true
  }

  private let logger = Logger(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.bridge)

  private let uuid: UUID

  private let usesInteractiveZsh: Bool
  private let cwd: URL
  private let nvimArgs: [String]
  private let envDict: [String: String]
  private let nvimBinary: String

  private var nvimServerProc: Process?
}

private let timeout = 5
