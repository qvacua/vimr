/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Nimble
import RxBlocking
import RxPack
import RxSwift
import XCTest

private extension PrimitiveSequenceType {
  func waitCompletion() throws {
    _ = try self.primitiveSequence.toBlocking().first()
  }
}

private func delayingCompletable() -> Completable {
  Single.just(0)
    .delay(.milliseconds(10), scheduler: MainScheduler.instance)
    .asCompletable()
}

/// No real test, just a sample code to see that it works with Neovim
class RxMsgpackRpcNeovimExample: XCTestCase {
  let rpc = RxMsgpackRpc(queueQos: .default)
  let disposeBag = DisposeBag()
  var proc: Process!

  override func setUp() {
    super.setUp()

    self.rpc.stream.subscribe(
      onNext: { msg in
        switch msg {
        case let .notification(method, params):
          print("NOTIFICATION: \(method): array of \(params.count) elements")
        case let .error(value, msg):
          print("ERROR: \(msg) with \(value)")
        case let .response(msgid, error, result):
          print("RESPONSE: \(msgid), \(error), \(result)")
        default:
          fail("Unknown msg type from rpc")
        }
      },
      onError: { print("ERROR: \($0)") },
      onCompleted: { print("COMPLETED!") }
    )
    .disposed(by: self.disposeBag)

    self.proc = neovimProcess()
    let inPipe = self.proc.standardInput as! Pipe
    let outPipe = self.proc.standardOutput as! Pipe
    let errorPipe = self.proc.standardError as! Pipe
    try! self.proc.run()
    try! self.rpc.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe).waitCompletion()
  }

  override func tearDown() {
    super.tearDown()

    try! self.rpc.request(
      method: "nvim_command", params: [.string("q!")],
      expectsReturnValue: false
    ).waitCompletion()

    try! self.rpc.stop().waitCompletion()
    self.proc.waitUntilExit()
  }

  func testExample() throws {
    try self.rpc.request(
      method: "nvim_ui_attach",
      params: [80, 24, [:]],
      expectsReturnValue: false
    ).waitCompletion()

    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    for i in 0...100 {
      let date = Date()
      let response = try self.rpc
        .request(
          method: "nvim_exec2",
          params: [.string("echo '\(i) \(formatter.string(from: date))'"), ["output": true]],
          expectsReturnValue: true
        )
        .toBlocking().first()!

      Swift.print(response)
    }

    let testFileUrl: URL = FileManager.default
      .homeDirectoryForCurrentUser.appending(components: "test/big.swift")
    guard FileManager.default.fileExists(atPath: testFileUrl.path) else {
      try self.rpc.request(method: "nvim_ui_detach", params: [], expectsReturnValue: false)
        .waitCompletion()

      return
    }

    try self.rpc.request(
      method: "nvim_command",
      params: [.string("e \(testFileUrl.path)")],
      expectsReturnValue: false
    ).waitCompletion()

    let lineCount = try self.rpc.request(
      method: "nvim_buf_line_count",
      params: [.int(0)],
      expectsReturnValue: true
    )
    .toBlocking().first()!
    Swift.print("Line count of \(testFileUrl): \(lineCount)")

    let repeatCount = 200
    for _ in 0...repeatCount {
      try self.rpc
        .request(method: "nvim_input", params: ["<PageDown>"], expectsReturnValue: false)
        .waitCompletion()
      try delayingCompletable().waitCompletion()
    }
    for _ in 0...repeatCount {
      try self.rpc
        .request(method: "nvim_input", params: ["<PageUp>"], expectsReturnValue: false)
        .waitCompletion()
      try delayingCompletable().waitCompletion()
    }

    Thread.sleep(forTimeInterval: 1)

    try self.rpc.request(method: "nvim_ui_detach", params: [], expectsReturnValue: false)
      .waitCompletion()
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
