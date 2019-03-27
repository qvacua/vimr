/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import RxSwift

class RxMsgpackRpcTests: XCTestCase {
  
  private var connection: MsgpackRpc!
  private let disposeBag = DisposeBag()
  
  override func setUp() {
    super.setUp()
    
    // $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim --headless $SOMEFILE
    connection = MsgpackRpc()
    connection.stream
      .subscribe(onNext: { msg in
        switch msg {
        case let .notification(method, params):
          print("NOTIFICATION: \(method): array of \(params.count) elements")
        case let .error(value, msg):
          print("ERROR: \(msg) with \(value)")
        default:
          print("???")
        }
      }, onError: { print("ERROR: \($0)") })
      .disposed(by: self.disposeBag)
    
    _ = connection.run(at: "/tmp/nvim.sock")
      .andThen(connection.request(
        method: "nvim_ui_attach", params: [.int(40), .int(40), .map([:])], expectsReturnValue: true)
      )
      .syncValue()
  }
  
  override func tearDown() {
    super.tearDown()
    _ = self.connection.request(method: "nvim_command", params: [.string("q!")], expectsReturnValue: true).syncValue()
    try? self.connection.stop().wait()
  }
  
  func testExample() {
    let disposeBag = DisposeBag()
    
    let lineCount = connection
      .request(method: "nvim_buf_line_count", params: [.int(0)], expectsReturnValue: true)
      .syncValue()
    print(lineCount ?? "???")
    
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    for i in 0...100 {
      let date = Date()
      connection
        .request(method: "nvim_command_output",
                 params: [.string("echo '\(i) \(formatter.string(from: date))'")],
                 expectsReturnValue: true)
        .subscribe(onSuccess: { response in
          print(response)
        }, onError: { error in
          print(error)
        })
        .disposed(by: disposeBag)
    }
    
    sleep(2)
  }
}

extension PrimitiveSequence
  where Element == Never, TraitType == CompletableTrait {

  func wait(
    onCompleted: (() -> Void)? = nil,
    onError: ((Swift.Error) -> Void)? = nil
  ) throws {
    var trigger = false
    var err: Swift.Error? = nil

    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onCompleted: {
      onCompleted?()

      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    }, onError: { error in
      onError?(error)
      err = error

      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    })

    while !trigger { condition.wait(until: Date(timeIntervalSinceNow: 5)) }
    disposable.dispose()

    if let e = err {
      throw e
    }
  }
}

extension PrimitiveSequence where TraitType == SingleTrait {

  static func fromSinglesToSingleOfArray(
    _ singles: [Single<Element>]
  ) -> Single<[Element]> {
    return Observable
      .merge(singles.map { $0.asObservable() })
      .toArray()
      .asSingle()
  }

  func flatMapCompletable(
    _ selector: @escaping (Element) throws -> Completable
  ) -> Completable {
    return self
      .asObservable()
      .flatMap { try selector($0).asObservable() }
      .ignoreElements()
  }

  func syncValue() -> Element? {
    var trigger = false
    var value: Element?

    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onSuccess: { result in
      value = result

      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    }, onError: { error in
      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    })

    while !trigger { condition.wait(until: Date(timeIntervalSinceNow: 5)) }
    disposable.dispose()

    return value
  }

  func asCompletable() -> Completable {
    return self.asObservable().ignoreElements()
  }
}
