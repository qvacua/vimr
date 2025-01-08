/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import Foundation
import MessagePack
import NvimApi
import os

let kMinAlphaVersion = 0
let kMinMinorVersion = 9
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

  func runLocalServerAndNvim(width: Int, height: Int) throws -> (Pipe, Pipe, Pipe) {
    self.initialWidth = width
    self.initialHeight = height

    return try self.launchNvimUsingLoginShellEnv()
  }

  func quit() {
    self.nvimServerProc?.waitUntilExit()
    self.log.info("NvimServer \(self.uuid) exited successfully.")
  }

  func forceQuit() {
    self.log.fault("Force-exiting NvimServer \(self.uuid).")
    self.forceExitNvimServer()
    self.log.fault("NvimServer \(self.uuid) was forcefully exited.")
  }

  private func forceExitNvimServer() {
    self.nvimServerProc?.interrupt()
    self.nvimServerProc?.terminate()
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

    process.arguments = ["--embed"] + self.nvimArgs

    self.log.debug(
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
}

private let timeout = 5
