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

  /// Launch nvim in headless mode with --listen only (no --embed, no stdio pipes).
  /// Used for socket-launch mode: we connect to the socket afterwards.
  func runLocalServerHeadless() throws {
    try self.launchNvimHeadless()
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

  private func launchNvimHeadless() throws {
    var env = self.envDict

    let process = Process()
    // Redirect stdio to /dev/null — we connect via the --listen socket, not pipes.
    let devNull = FileHandle.nullDevice
    process.standardInput = devNull
    process.standardOutput = devNull
    process.standardError = devNull
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
    // --headless (not --embed) is intentional here. The nvim docs say
    // "UI embedders that want the UI protocol on a socket must pass --embed --listen".
    // That pattern applies when the parent process drives nvim via stdio RPC AND
    // also wants a socket — which is what pipe mode (launchNvimUsingLoginShellEnv)
    // does with ["--embed", "--listen", ...].
    //
    // This socket-launch mode is different: VimR is NOT the stdio parent.
    // nvim must run independently with its own event loop. Using --embed here
    // would cause nvim to exit immediately when it reads EOF on the /dev/null stdin.
    // --headless starts nvim without a TUI but with a live event loop, creates the
    // socket, and keeps running until explicitly quit — exactly what we need.
    process.arguments = ["--headless", "--listen", self.pipeUrl.path] + self.nvimArgs

    dlog.debug("Servername (headless): \(self.pipeUrl.path)")
    dlog.debug(
      "Launching NvimServer (headless) \(String(describing: process.launchPath)) with args: \(String(describing: process.arguments))"
    )
    do {
      try process.run()
    } catch {
      throw NvimApi.Error.exception(message: "Could not run neovim process (headless).")
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
