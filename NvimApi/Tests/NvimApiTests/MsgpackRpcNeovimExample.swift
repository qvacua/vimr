/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import NvimApi
import Testing

/// No real test, just a sample code to see that it works with Neovim
class MsgpackRpcNeovimExample {
  let rpc = MsgpackRpc()
  let proc: Process

  init() async throws {
    self.proc = neovimProcess()
    let inPipe = self.proc.standardInput as! Pipe
    let outPipe = self.proc.standardOutput as! Pipe
    let errorPipe = self.proc.standardError as! Pipe
    try self.proc.run()

    let stream = await self.rpc.messagesStream

    try await self.rpc.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)

    Task.detached {
      for await msg in stream {
        switch msg {
        case let .notification(method, params):
          Swift.print("NOTIFICATION: \(method): array of \(params.count) elements")
        case let .error(value, msg):
          Swift.print("ERROR: \(msg) with \(value)")
        case let .response(msgid, error, result):
          Swift.print("RESPONSE: \(msgid), \(error), \(result)")
        default:
          Issue.record("Unknown msg type from rpc")
        }
      }
    }
  }

  func cleanUp() async throws {
    _ = try await self.rpc.request(
      method: "nvim_command", params: [.string("q!")],
      expectsReturnValue: false
    )

    await self.rpc.stop()
    self.proc.waitUntilExit()
  }

  @Test func testExample() async throws {
    Swift.print("###############################################")
    _ = try await self.rpc.request(
      method: "nvim_ui_attach",
      params: [80, 24, [:]],
      expectsReturnValue: false
    )

    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    for i in 0...100 {
      let date = Date()
      let response = try await self.rpc
        .request(
          method: "nvim_exec2",
          params: [.string("echo '\(i) \(formatter.string(from: date))'"), ["output": true]],
          expectsReturnValue: true
        )
      Swift.print(response)
    }

    let testFileUrl: URL = FileManager.default
      .homeDirectoryForCurrentUser.appending(components: "test/big.swift")
    guard FileManager.default.fileExists(atPath: testFileUrl.path) else {
      try await self.cleanUp()
      return
    }

    _ = try await self.rpc.request(
      method: "nvim_command",
      params: [.string("e \(testFileUrl.path)")],
      expectsReturnValue: false
    )

    let lineCount = try await self.rpc.request(
      method: "nvim_buf_line_count",
      params: [.int(0)],
      expectsReturnValue: true
    )
    Swift.print("Line count of \(testFileUrl): \(lineCount)")

    let repeatCount = 200
    for _ in 0...repeatCount {
      _ = try await self.rpc
        .request(method: "nvim_input", params: ["<PageDown>"], expectsReturnValue: false)
    }
    for _ in 0...repeatCount {
      _ = try await self.rpc
        .request(method: "nvim_input", params: ["<PageUp>"], expectsReturnValue: false)
    }

    _ = try await self.rpc.request(
      method: "nvim_ui_detach", params: [], expectsReturnValue: false
    )

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
