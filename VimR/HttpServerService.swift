/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

fileprivate func shareFile(_ path: String) -> ((HttpRequest) -> HttpResponse) {
  return { r in
    guard let file = try? path.openForReading() else {
      return .notFound
    }

    return .raw(200, "OK", [:], { writer in
      try? writer.write(file)
      file.close()
    })
  }
}

class HttpServerService: Service {

  typealias Element = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  init(port: in_port_t) {
    self.port = port
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

  func apply(_ pair: Element) {
    guard case .setCurrentBuffer = pair.action else {
      return
    }

    let preview = pair.state.payload.preview
    guard let buffer = preview.buffer, let html = preview.html, let server = preview.server else {
      return
    }

    NSLog("Serving \(html) on \(server)")

    let htmlBasePath = server.deletingLastPathComponent().path
    let cssPath = self.resourceBaesUrl.appendingPathComponent("github-markdown.css").path

    self.server["\(htmlBasePath)/:path"] = shareFilesFromDirectory(buffer.deletingLastPathComponent().path)
    self.server.GET[server.path] = shareFile(html.path)
    self.server.GET["\(htmlBasePath)/github-markdown.css"] = shareFile(cssPath)
  }

  fileprivate let server = HttpServer()
  fileprivate let resourceBaesUrl = Bundle.main.resourceURL!.appendingPathComponent("markdown")
  fileprivate let port: in_port_t
}
