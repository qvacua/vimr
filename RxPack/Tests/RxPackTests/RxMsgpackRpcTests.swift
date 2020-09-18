/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import RxSwift
import XCTest

@testable import RxPack

class RxMsgpackRpcTests: XCTestCase {
  private var connection: RxMsgpackRpc!
  private let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()

    // $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim --headless $SOMEFILE
    self.connection = RxMsgpackRpc()
    self.connection.stream
      .subscribe(
        onNext: { msg in
          switch msg {
          case let .notification(method, params):
            print("NOTIFICATION: \(method): array of \(params.count) elements")
          case let .error(value, msg):
            print("ERROR: \(msg) with \(value)")
          default:
            print("???")
          }
        },
        onError: { print("ERROR: \($0)") },
        onCompleted: { print("COMPLETED!") }
      )
      .disposed(by: self.disposeBag)

    _ = try? self.connection.run(at: "/tmp/nvim.sock").wait()
//      .andThen(self.connection.request(
//        method: "nvim_ui_attach",
//        params: [.int(40), .int(40), .map([:])],
//        expectsReturnValue: true
//      ))
//      .syncValue()
  }

  override func tearDown() {
    super.tearDown()
    try? self.connection
      .request(
        method: "nvim_command", params: [.string("q!")],
        expectsReturnValue: false
      )
      .asCompletable()
      .wait()
    try? self.connection.stop().wait()
  }

  func testExample() {
    let disposeBag = DisposeBag()

    let lineCount = self.connection
      .request(
        method: "nvim_buf_line_count",
        params: [.int(0)],
        expectsReturnValue: true
      )
      .syncValue()
    print(lineCount ?? "???")

    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    for i in 0...100 {
      let date = Date()
      connection
        .request(
          method: "nvim_command_output",
          params: [.string("echo '\(i) \(formatter.string(from: date))'")],
          expectsReturnValue: true
        )
        .subscribe(
          onSuccess: { response in print(response) },
          onError: { error in print(error) }
        )
        .disposed(by: disposeBag)
    }

    sleep(30)
  }
}
