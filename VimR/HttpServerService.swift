/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

protocol Service {

  associatedtype StateType

  func apply(_: Observable<StateType>) -> Observable<StateType>
}

class HttpServerService: Service {

  typealias StateType = UuidState<MainWindow.State>

  init(port: in_port_t) {
    do {
      try self.server.start(port)
      NSLog("server started on http://localhost:\(port)")

      self.server["/tools/preview/error"] = { r in .ok(.html("ERROR!")) }
      self.server["/tools/preview/save-first"] = { r in .ok(.html("SAVE FIRST!")) }
      self.server["/tools/preview/empty"] = { r in .ok(.html("NO PREVIEW!")) }
    } catch {
      NSLog("ERROR server could not be started on port \(port)")
    }
  }

  func apply(_ source: Observable<StateType>) -> Observable<StateType> {
    NSLog("\(#file): \(#function)")
    return source
  }

  fileprivate let server = HttpServer()
}
