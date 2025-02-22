/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import NvimApi
import Testing

class NvimApiSyncTest {
  var api: NvimApiSync!
  let proc: Process

  init() throws {
    self.proc = neovimProcess()
    try self.proc.run()

    self.api = try NvimApiSync()
    try self.api.run(socketPath: "/tmp/nvim-api-sync-test.socket")
  }

  @Test func testSyncApi() throws {
    print(self.api.nvimCommand(command: "e ~/test/big.swift"))
    print(self.api.nvimGetVvar(name: "servername"))
    try print(self.api.nvimBufLineCount(buffer: self.api.nvimGetCurrentBuf().get()))

    self.api.stop()
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
  process.arguments = "--listen /tmp/nvim-api-sync-test.socket"
    .split(separator: " ")
    .map(String.init)

  return process
}
