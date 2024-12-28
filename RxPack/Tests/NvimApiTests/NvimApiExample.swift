/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import NvimApi
import Testing

/// No real test, just a sample code to see that it works with Neovim
class NvimApiExample {
  let api = NvimApi()
  var proc: Process

  init() async throws {
    self.proc = neovimProcess()
    let inPipe = self.proc.standardInput as! Pipe
    let outPipe = self.proc.standardOutput as! Pipe
    let errorPipe = self.proc.standardError as! Pipe
    try self.proc.run()

    let stream = await self.api.msgpackRawStream

    try await self.api.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)

    Task.detached {
      for await msg in stream {
        switch msg {
        case let .notification(method, params):
          print("NOTIFICATION: \(method): array of \(params.count) elements")
        case let .error(value, msg):
          print("ERROR: \(msg) with \(value)")
        case let .response(msgid, error, result):
          print("RESPONSE: \(msgid), \(error), \(result)")
        default:
          Issue.record("Unknown msg type from rpc")
        }
      }
    }
  }

  func cleanUp() async throws {
    try await self.api.nvimCommand(command: "q!").get()
    self.proc.waitUntilExit()
  }

  @Test func testExample() async throws {
    try await self.api.nvimUiAttach(width: 80, height: 24, options: [:]).get()

    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    for i in 0...100 {
      let date = Date()
      let response = try await self.api.nvimExec2(
        src: "echo '\(i) \(formatter.string(from: date))'", opts: ["output": true]
      ).get()
      Swift.print(response)
    }

    let testFileUrl: URL = FileManager.default
      .homeDirectoryForCurrentUser.appending(components: "test/big.swift")
    guard FileManager.default.fileExists(atPath: testFileUrl.path) else {
      try await self.api.nvimUiDetach().get()

      return
    }

    try await self.api.nvimCommand(command: "e \(testFileUrl.path)").get()

    let lineCount = try await self.api.nvimBufLineCount(buffer: .init(0)).get()
    Swift.print("Line count of \(testFileUrl): \(lineCount)")

    let repeatCount = 10
    for _ in 0...repeatCount {
      _ = try await self.api.nvimInput(keys: "<PageDown>").get()
      Swift.print("############################ PageDown")
    }
    for _ in 0...repeatCount {
      _ = try await self.api.nvimInput(keys: "<PageUp>").get()
      Swift.print("############################ PageUp")
    }

    try await self.api.nvimUiDetach().get()
    try await self.cleanUp()
  }
}

private func neovimProcess() -> Process {
  let inPipe = Pipe()
  let outPipe = Pipe()
  let errorPipe = Pipe()

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nvim")
  process.standardInput = inPipe
  process.standardError = errorPipe
  process.standardOutput = outPipe
  process.arguments = ["--embed"]

  return process
}

private let nanoSecondsPerSecond: UInt64 = 1_000_000_000
