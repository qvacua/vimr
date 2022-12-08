/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Nimble
import RxBlocking
import RxPack
import RxSwift
import XCTest

@testable import RxPack

class RxMessagePortTest: XCTestCase {
  let disposeBag = DisposeBag()

  let serverName = "com.qvacua.RxPack.RxMessagePortTest.server.\(UUID().uuidString)"
  let server = RxMessagePortServer(queueQos: .default)
  let client = RxMessagePortClient(queueQos: .default)

  override func setUp() {
    super.setUp()

    self.server
      .stream
      .subscribe(onNext: nil)
      .disposed(by: self.disposeBag)

    _ = try! self.server
      .run(as: self.serverName)
      .andThen(self.client.connect(to: self.serverName))
      .toBlocking()
      .first()
  }

  override func tearDown() {
    super.tearDown()

    _ = try! self.client
      .stop()
      .andThen(self.server.stop())
      .toBlocking()
      .first()
  }

  func testSth() {
    self.server
      .syncReplyBody = { msgid, inputData in data("response-to-\(msgid)-\(str(inputData))") }

    var response = try! self.client
      .send(msgid: 0, data: data("first-msg"), expectsReply: true)
      .toBlocking()
      .first()!
    expect(str(response)).to(equal("response-to-0-first-msg"))

    response = try! self.client
      .send(msgid: 1, data: data("second-msg"), expectsReply: true)
      .toBlocking()
      .first()!
    expect(str(response)).to(equal("response-to-1-second-msg"))
  }
}

private func str(_ data: Data?) -> String { String(data: data!, encoding: .utf8)! }
private func data(_ str: String) -> Data { str.data(using: .utf8)! }
