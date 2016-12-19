/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PreviewService {

  fileprivate let emptyPreviewHtml: String

  init() {

    guard let emptyUrl = Bundle.main.url(forResource: "empty-preview",
                                         withExtension: "html",
                                         subdirectory: "preview")
      else {
      preconditionFailure("No empty-preview.html!")
    }

    guard let emptyHtml = try? String(contentsOf: emptyUrl) else {
      preconditionFailure("Error getting empty-preview.html!")
    }

    self.emptyPreviewHtml = emptyHtml
  }

  func emptyPreview() -> String {
    return self.emptyPreviewHtml
  }
}
