/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import MessagePack
import Nimble
import RxBlocking
import RxPack
import RxSwift
import XCTest

// class RxMsgpackRpcrTests: XCTestCase {
//  typealias Value = RxMsgpackRpc.Value
//  typealias Message = RxMsgpackRpc.Message
//  typealias MessageType = RxMsgpackRpc.MessageType
//
//  var testFinished = false
//  let testFinishedCond = NSCondition()
//
//  var serverReady = false
//  let serverReadyCond = NSCondition()
//
//  var server: TestServer!
//  var clientSocket: Socket!
//  let msgpackRpc = RxMsgpackRpc(queueQos: .default)
//
//  var requestsFromClient = [[Value]]()
//  let responseScheduler = ConcurrentDispatchQueueScheduler(qos: .default)
//  let disposeBag = DisposeBag()
//
//  let uuid = UUID().uuidString
//
//  override func setUp() {
//    super.setUp()
//
//    self.server = TestServer(
//      path: FileManager.default
//        .temporaryDirectory
//        .appendingPathComponent("\(self.uuid).sock")
//        .path
//    )
//
//    self.server.queue.async {
//      self.server.waitForClientAndStartReading()
//      self.clientSocket = self.server.connectedSocket
//
//      self.serverReadyCond.lock()
//      self.serverReady = true
//      self.serverReadyCond.signal()
//      self.serverReadyCond.unlock()
//    }
//  }
//
//  override func tearDown() {
//    _ = try! self.msgpackRpc.stop().toBlocking().first()
//    self.server.shutdownServer()
//
//    super.tearDown()
//  }
//
//  func testResponsesFromServer() {
//    self.runClient(readBufferSize: Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE)
//
//    var beginAssertion = false
//    let beginAssertionCond = NSCondition()
//
//    self.assertMsgsFromClient { data, _ in
//      // WARNING:
//      // - Sometimes, the first and the second message get coalesced to one read operation by the
//      // server.
//      // - Sometimes, second message arrives first.
//      let requests = try! unpackAll(data)
//        .map(\.arrayValue!)
//        .sorted { left, right in left[2].stringValue! < right[2].stringValue! }
//
//      for request in requests {
//        expect(request).to(haveCount(4))
//        self.requestsFromClient.append(request)
//
//        if request[2].stringValue! == "2-second-request" {
//          beginAssertionCond.lock()
//          beginAssertion = true
//          beginAssertionCond.signal()
//          beginAssertionCond.unlock()
//        }
//      }
//    }
//
//    var responseCount = 0
//    self.sendRequests {
//      self.msgpackRpc
//        .request(method: "1-first-request", params: [.uint(123)], expectsReturnValue: true)
//        .subscribe(on: self.responseScheduler)
//        .subscribe(onSuccess: { response in
//          expect(response.error).to(equal(.nil))
//          expect(response.result).to(equal(.float(0.321)))
//          responseCount += 1
//
//          self.signalEndOfTest()
//        })
//        .disposed(by: self.disposeBag)
//
//      self.msgpackRpc
//        .request(method: "2-second-request", params: [.uint(321)], expectsReturnValue: true)
//        .subscribe(on: self.responseScheduler)
//        .subscribe(onSuccess: { response in
//          expect(response.error).to(equal(.nil))
//          expect(response.result).to(equal(.float(0.123)))
//          responseCount += 1
//        })
//        .disposed(by: self.disposeBag)
//
//      beginAssertionCond.lock()
//      while beginAssertion == false {
//        beginAssertionCond.wait(until: Date(timeIntervalSinceNow: 2 * 60))
//      }
//      beginAssertionCond.unlock()
//
//      let request1 = self.requestsFromClient[0]
//      expect(request1[0].uint64Value).to(equal(MessageType.request.rawValue))
//      expect(request1[2].stringValue).to(equal("1-first-request"))
//      expect(request1[3].arrayValue).to(equal([.uint(123)]))
//
//      let request2 = self.requestsFromClient[1]
//      expect(request2[0].uint64Value).to(equal(MessageType.request.rawValue))
//      expect(request2[2].stringValue).to(equal("2-second-request"))
//      expect(request2[3].arrayValue).to(equal([.uint(321)]))
//
//      try! self.clientSocket
//        .write(from: self.dataForResponse(msgid: 1, error: .nil, params: .float(0.123)))
//
//      try! self.clientSocket
//        .write(from: self.dataForResponse(msgid: 0, error: .nil, params: .float(0.321)))
//    }
//
//    expect(responseCount).to(equal(2))
//  }
//
//  func testNotificationsFromServer() {
//    DispatchQueue.global(qos: .default).async {
//      let msgs = try! self.msgpackRpc.stream.toBlocking().toArray()
//      expect(msgs).to(haveCount(2))
//
//      let (method1, params1) = self.notification(from: msgs[0])
//      let (method2, params2) = self.notification(from: msgs[1])
//
//      expect(method1).to(equal("first-msg"))
//      expect(params1).to(haveCount(2))
//      expect(params1[0].uintValue).to(equal(321))
//      expect(params1[1].dataValue).to(haveCount(321))
//
//      expect(method2).to(equal("second-msg"))
//      expect(params2).to(haveCount(2))
//      expect(params2[0].dataValue).to(haveCount(123))
//      expect(params2[1].floatValue).to(equal(0.123))
//
//      self.signalEndOfTest()
//    }
//
//    self.runClient(readBufferSize: Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE)
//
//    self.sendRequests {
//      let data1 = dataForNotification(
//        method: "first-msg",
//        params: [.uint(321), .binary(.random(ofCount: 321))]
//      )
//      let data2 = dataForNotification(
//        method: "second-msg",
//        params: [.binary(.random(ofCount: 123)), .float(0.123)]
//      )
//
//      try! self.clientSocket.write(from: data1)
//      try! self.clientSocket.write(from: data2)
//
//      self.server.shutdownServer()
//    }
//  }
//
//  func testPartialRequestFromServer() {
//    DispatchQueue.global(qos: .default).async {
//      let msgs = try! self.msgpackRpc.stream.toBlocking().toArray()
//      expect(msgs).to(haveCount(2))
//
//      let (method1, params1) = self.notification(from: msgs[0])
//      let (method2, params2) = self.notification(from: msgs[1])
//
//      expect(method1).to(equal("first-msg"))
//      expect(params1).to(haveCount(2))
//      expect(params1[0].uintValue).to(equal(321))
//      expect(params1[1].dataValue).to(haveCount(321))
//
//      expect(method2).to(equal("second-msg"))
//      expect(params2).to(haveCount(2))
//      expect(params2[0].dataValue).to(haveCount(123))
//      expect(params2[1].floatValue).to(equal(0.123))
//
//      self.signalEndOfTest()
//    }
//
//    self.runClient(readBufferSize: Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE)
//    self.sendRequests {
//      let data1 = dataForNotification(
//        method: "first-msg",
//        params: [.uint(321), .binary(.random(ofCount: 321))]
//      )
//      let data2 = dataForNotification(
//        method: "second-msg",
//        params: [.binary(.random(ofCount: 123)), .float(0.123)]
//      )
//
//      var msg1 = data1
//      msg1.append(data2[..<100])
//      let msg2 = data2[100...]
//
//      try! self.clientSocket.write(from: msg1)
//      try! self.clientSocket.write(from: msg2)
//
//      self.server.shutdownServer()
//    }
//  }
// }
//
// extension RxMsgpackRpcrTests {
//  func dataForResponse(msgid: UInt64, error: Value, params: Value) -> Data {
//    pack(.array([
//      .uint(MessageType.response.rawValue),
//      .uint(msgid),
//      error,
//      params,
//    ]))
//  }
//
//  func dataForNotification(method: String, params: [Value]) -> Data {
//    pack(.array([
//      .uint(MessageType.notification.rawValue),
//      .string(method),
//      .array(params),
//    ]))
//  }
//
//  func assertMsgsFromClient(assertFn: @escaping TestServer.DataReadCallback) {
//    self.server.dataReadCallback = assertFn
//  }
//
//  func runClient(readBufferSize: Int) {
//    usleep(500)
//    _ = try! self.msgpackRpc
//      .run(at: self.server.path, readBufferSize: readBufferSize)
//      .toBlocking()
//      .first()
//
//    self.serverReadyCond.lock()
//    while self.serverReady == false {
//      self.serverReadyCond.wait(until: Date(timeIntervalSinceNow: 2 * 60))
//    }
//    self.serverReadyCond.unlock()
//  }
//
//  func sendRequests(requestFn: () -> Void) {
//    requestFn()
//    self.waitForAssertions()
//  }
//
//  func signalEndOfTest() {
//    self.testFinishedCond.lock()
//    self.testFinished = true
//    self.testFinishedCond.signal()
//    self.testFinishedCond.unlock()
//  }
//
//  func waitForAssertions() {
//    var signalled = false
//    self.testFinishedCond.lock()
//    while self.testFinished == false {
//      signalled = self.testFinishedCond.wait(until: Date(timeIntervalSinceNow: 2 * 60))
//    }
//    expect(signalled).to(beTrue())
//    self.testFinishedCond.unlock()
//  }
//
//  func notification(from msg: Message) -> (method: String, params: [Value]) {
//    guard case let .notification(method, params) = msg else {
//      preconditionFailure("\(msg) is not a notification")
//    }
//
//    return (method: method, params: params)
//  }
// }
//
///// Modified version of the example in the README of https://github.com/Kitura/BlueSocket.
///// It only supports one connection. Everywhere ! and no error handling whatsoever.
// class TestServer {
//  typealias DataReadCallback = (Data, Int) -> Void
//
//  let queue = DispatchQueue(label: "com.qvacua.RxPack.TestServer")
//  var connectedSocket: Socket!
//
//  var path: String
//  var readBufferSize: Int = 1024 * 1024
//  var dataReadCallback: DataReadCallback = { _, _ in }
//
//  private var listenSocket: Socket!
//
//  init(path: String) { self.path = path }
//  deinit { self.shutdownServer() }
//
//  func waitForClientAndStartReading() {
//    self.listenSocket = try! Socket.create(family: .unix)
//
//    try! self.listenSocket.listen(on: self.path)
//    let newSocket = try! self.listenSocket.acceptClientConnection()
//    self.connectedSocket = newSocket
//
//    self.readData(from: newSocket)
//  }
//
//  func readData(from socket: Socket) {
//    self.queue.async { [unowned self] in
//      var shouldKeepRunning = true
//
//      var readData = Data(capacity: self.readBufferSize)
//      repeat {
//        guard let bytesRead = try? socket.read(into: &readData) else {
//          shouldKeepRunning = false
//          break
//        }
//
//        if bytesRead > 0 {
//          self.dataReadCallback(readData, bytesRead)
//        } else {
//          shouldKeepRunning = false
//          break
//        }
//
//        readData.count = 0
//      } while shouldKeepRunning
//
//      socket.close()
//    }
//  }
//
//  func shutdownServer() {
//    self.connectedSocket?.close()
//    self.listenSocket?.close()
//  }
// }
//
// extension Data {
//  static func random(ofCount count: Int) -> Data {
//    Data((0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })
//  }
// }
