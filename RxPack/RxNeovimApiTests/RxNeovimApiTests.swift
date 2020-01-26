/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import RxSwift
import MessagePack

class NvimMsgPackTests: XCTestCase {

  var nvim = RxNeovimApi()
  let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()

    // $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
    try? nvim.run(at: "/tmp/nvim.sock").wait()
  }

  override func tearDown() {
    super.tearDown()
    try? self.nvim.stop().wait()
  }

  func testSth() {
    nvim
      .command(command: "pwd")
      .subscribe(onCompleted: { print("completed") }, onError: { print($0) })
//      .subscribe(onSuccess: { print($0) })
      .disposed(by: self.disposeBag)

    sleep(1)
  }

  func testExample() {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .full
    let now = Date()
    let dispose = DisposeBag()
    for i in 0...5 {
      nvim
        .command(
          command: "echo '\(formatter.string(from: now)) \(i)'"
        )
        .subscribe(onCompleted: { print("\(i) handled") })
        .disposed(by: dispose)
    }

    sleep(1)
  }
}
