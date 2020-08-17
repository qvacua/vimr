/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

public final class RxMessagePortClient {
  public enum ResponseCode {
    // Unfortunately, case success = kCFMessagePortSuccess is not possible.
    case success
    case sendTimeout
    case receiveTimeout
    case isInvalid
    case transportError
    case becameInvalidError
    case unknown

    fileprivate init(rawResponseCode code: Int32) {
      switch code {
      case kCFMessagePortSuccess: self = .success
      case kCFMessagePortSendTimeout: self = .sendTimeout
      case kCFMessagePortReceiveTimeout: self = .receiveTimeout
      case kCFMessagePortIsInvalid: self = .isInvalid
      case kCFMessagePortTransportError: self = .transportError
      case kCFMessagePortBecameInvalidError: self = .becameInvalidError
      default: self = .unknown
      }
    }
  }

  public enum Error: Swift.Error {
    case serverInit
    case clientInit
    case portInvalid
    case send(msgid: Int32, response: ResponseCode)
  }

  public static let defaultTimeout = CFTimeInterval(5)

  public let uuid = UUID()
  public var timeout = RxMessagePortClient.defaultTimeout

  public init() {
    self.queue = DispatchQueue(
      label: "\(String(reflecting: RxMessagePortClient.self))-\(self.uuid.uuidString)",
      qos: .userInitiated
    )
  }

  public func send(
    msgid: Int32,
    data: Data?,
    expectsReply: Bool
  ) -> Single<Data?> {
    Single.create { single in
      self.queue.async {
        guard self.portIsValid else {
          single(.error(Error.portInvalid))
          return
        }

        let returnDataPtr = UnsafeMutablePointer<Unmanaged<CFData>?>.allocate(capacity: 1)
        defer { returnDataPtr.deallocate() }

        let responseCode = CFMessagePortSendRequest(
          self.port,
          msgid,
          data?.cfdata,
          self.timeout,
          self.timeout,
          expectsReply ? CFRunLoopMode.defaultMode.rawValue : nil,
          expectsReply ? returnDataPtr : nil
        )

        guard responseCode == kCFMessagePortSuccess else {
          single(.error(
            Error.send(msgid: msgid, response: ResponseCode(rawResponseCode: responseCode))
          ))
          return
        }

        guard expectsReply else {
          single(.success(nil))
          return
        }

        // Upon return, [returnData] contains a CFData object
        // containing the reply data. Ownership follows the The Create Rule.
        // From: https://developer.apple.com/documentation/corefoundation/1543076-cfmessageportsendrequest
        // This means that we have to release the returned CFData.
        // Thus, we have to use Unmanaged.takeRetainedValue()
        // See also https://www.mikeash.com/pyblog/friday-qa-2017-08-11-swiftunmanaged.html
        let data: Data? = returnDataPtr.pointee?.takeRetainedValue().data
        single(.success(data))
      }

      return Disposables.create()
    }
  }

  public func connect(to name: String) -> Completable {
    Completable.create { completable in
      self.queue.async {
        self.port = CFMessagePortCreateRemote(kCFAllocatorDefault, name.cfstr)

        if self.port == nil {
          completable(.error(Error.clientInit))
          return
        }

        self.portIsValid = true
        completable(.completed)
      }

      return Disposables.create()
    }
  }

  public func stop() -> Completable {
    Completable.create { completable in
      self.queue.async {
        self.portIsValid = false
        if self.port != nil && CFMessagePortIsValid(self.port) {
          CFMessagePortInvalidate(self.port)
        }
        completable(.completed)
      }

      return Disposables.create()
    }
  }

  private var portIsValid = false
  private var port: CFMessagePort?

  private let queue: DispatchQueue
}

public final class RxMessagePortServer {
  public typealias SyncReplyBody = (Int32, Data?) -> Data?

  public struct Message {
    public var msgid: Int32
    public var data: Data?
  }

  public let uuid = UUID()

  public var syncReplyBody: SyncReplyBody? {
    get { self.messageHandler.syncReplyBody }
    set { self.messageHandler.syncReplyBody = newValue }
  }

  public var stream: Observable<Message> { self.streamSubject.asObservable() }

  public init() {
    self.queue = DispatchQueue(
      label: "\(String(reflecting: RxMessagePortClient.self))-\(self.uuid.uuidString)",
      qos: .userInitiated
    )
    self.messageHandler = MessageHandler(subject: self.streamSubject)
  }

  public func run(as name: String) -> Completable {
    Completable.create { completable in
      self.queue.async {
        var localCtx = CFMessagePortContext(
          version: 0,
          info: Unmanaged.passUnretained(self.messageHandler).toOpaque(),
          retain: nil,
          release: nil,
          copyDescription: nil
        )

        self.port = CFMessagePortCreateLocal(
          kCFAllocatorDefault,
          name.cfstr,
          { _, msgid, data, info in
            guard let infoPtr = UnsafeRawPointer(info) else { return nil }

            let handler = Unmanaged<MessageHandler>.fromOpaque(infoPtr).takeUnretainedValue()
            return handler.handleMessage(msgId: msgid, cfdata: data)
          },
          &localCtx,
          nil
        )

        if self.port == nil {
          self.streamSubject.onError(RxMessagePortClient.Error.serverInit)
          completable(.error(RxMessagePortClient.Error.serverInit))
        }

        self.portThread = Thread { self.runServer() }
        self.portThread?.name
          = "\(String(reflecting: RxMessagePortServer.self))-\(self.uuid.uuidString)"
        self.portThread?.start()

        completable(.completed)
      }

      return Disposables.create()
    }
  }

  public func stop() -> Completable {
    Completable.create { completable in
      self.queue.async {
        self.messageHandler.syncReplyBody = nil
        self.streamSubject.onCompleted()

        if let portRunLoop = self.portRunLoop { CFRunLoopStop(portRunLoop) }

        if self.port != nil && CFMessagePortIsValid(self.port) {
          CFMessagePortInvalidate(self.port)
        }

        completable(.completed)
      }

      return Disposables.create()
    }
  }

  private var port: CFMessagePort?
  private var portThread: Thread?
  private var portRunLoop: CFRunLoop?

  private let queue: DispatchQueue

  private var messageHandler: MessageHandler
  private let streamSubject = PublishSubject<Message>()

  private func runServer() {
    self.portRunLoop = CFRunLoopGetCurrent()
    let runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, self.port, 0)
    CFRunLoopAddSource(self.portRunLoop, runLoopSrc, .defaultMode)
    CFRunLoopRun()
  }
}

private class MessageHandler {
  fileprivate var syncReplyBody: RxMessagePortServer.SyncReplyBody?

  fileprivate init(subject: PublishSubject<RxMessagePortServer.Message>) { self.subject = subject }

  fileprivate func handleMessage(
    msgId: Int32,
    cfdata: CFData?
  ) -> Unmanaged<CFData>? {
    let d = cfdata?.data

    self.subject.onNext(RxMessagePortServer.Message(msgid: msgId, data: d))

    guard let reply = self.syncReplyBody?(msgId, d) else { return nil }

    // The system releases the returned CFData object.
    // From https://developer.apple.com/documentation/corefoundation/cfmessageportcallback
    // See also https://www.mikeash.com/pyblog/friday-qa-2017-08-11-swiftunmanaged.html
    return Unmanaged.passRetained(reply.cfdata)
  }

  private let subject: PublishSubject<RxMessagePortServer.Message>
}

private extension Data {
  var cfdata: CFData { self as NSData }
}

private extension CFData {
  var data: Data { self as NSData as Data }
}

private extension String {
  var cfstr: CFString { self as NSString }
}
