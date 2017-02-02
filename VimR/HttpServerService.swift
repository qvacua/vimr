/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

protocol Service {

  associatedtype Pair

  func apply(_: Pair)
}

class HttpServerService: Service {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

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

  func apply(_ pair: Pair) {
    NSLog("!!!!!!!!!!!")
    let uuid = pair.state.uuid
    var state = pair.state.payload

    switch pair.action {

    case let .setCurrentBuffer(buffer):
      guard let url = buffer.url else {
        return
      }

      guard FileUtils.fileExists(at: url) else {
        return
      }

    case .close:
      return

    default:
      return

    }
  }

  fileprivate let server = HttpServer()
}
