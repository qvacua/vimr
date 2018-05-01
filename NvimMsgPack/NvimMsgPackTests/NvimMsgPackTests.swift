//
//  NvimMsgPackTests.swift
//  NvimMsgPackTests
//
//  Created by Tae Won Ha on 30.04.18.
//  Copyright © 2018 Tae Won Ha. All rights reserved.
//

import XCTest
@testable import NvimMsgPack
import RxSwift
import RxMsgpackRpc
import MessagePack

class NvimMsgPackTests: XCTestCase {

  var nvim: NvimApi!
  var stream: Observable<RxMsgpackRpc.Message>!
  let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()

    // $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
    guard let nvim = NvimApi(at: "/tmp/nvim.sock") else {
      preconditionFailure("Could not connect to nvim")
    }

    self.nvim = nvim
    try? nvim.connect()
  }

  override func tearDown() {
    super.tearDown()
    self.nvim.disconnect()
  }

  func testBufs() {
    Single.just([1, 2, 3])
      .asObservable()
      .flatMap { array in
        Observable.combineLatest(
          [1, 2, 3].map { idx -> Observable<String> in
            self.nvim.commandOutput(str: "echo \(idx)").asObservable()
          }
        )
      }
      .asSingle()
      .debug()
      .subscribe()
      .disposed(by: self.disposeBag)

    sleep(2)
  }

  func transform(buf: NvimApi.Buffer) -> Single<String> {
    return Single.create { single in
      single(.success("handle: \(buf.handle)"))

      return Disposables.create()
    }
  }

  func testExample() {
//    print(nvim.bufLineCount(buffer: NvimMsgPack.NvimApi.Buffer(0)).syncValue())
//    print(nvim.command(command: "pwd", expectsReturnValue: true, checkBlocked: true).syncValue())

    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .full
    let now = Date()
    let dispose = DisposeBag()
    for i in 0...5 {
      nvim
        .command(command: "echo '\(formatter.string(from: now)) \(i)'", expectsReturnValue: true, checkBlocked: true)
        .subscribe(onSuccess: { _ in
          print("\(i) handled")
        })
    }
  }
}
