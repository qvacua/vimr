/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import RxBlocking
import RxPack
import RxSwift
import XCTest

/// No real test, just a sample code to see that it works with Neovim: Execute
///
/// ```bash
/// NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim --headless $SOMEFILE
/// ```
///
/// in Terminal and rename xtestExample() to testExample() to run.
class RxMsgpackRpcNeovimExample: XCTestCase {
  let connection = RxMsgpackRpc(queueQos: .default)
  let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()

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

    _ = try! self.connection.run(at: "/tmp/nvim.sock").toBlocking().first()
  }

  override func tearDown() {
    super.tearDown()

    _ = try! self.connection
      .request(
        method: "nvim_command", params: [.string("q!")],
        expectsReturnValue: false
      )
      .toBlocking()
      .first()

    _ = try! self.connection.stop().toBlocking().first()
  }

  func xtestExample() {
    let lineCount = try! self.connection
      .request(
        method: "nvim_buf_line_count",
        params: [.int(0)],
        expectsReturnValue: true
      )
      .toBlocking()
      .first()

    print(lineCount!)

    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    for i in 0...100 {
      let date = Date()
      let response = try! self.connection
        .request(
          method: "nvim_command_output",
          params: [.string("echo '\(i) \(formatter.string(from: date))'")],
          expectsReturnValue: true
        )
        .toBlocking()
        .first()

      print(response!)
    }
  }
}
