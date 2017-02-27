///**
// * Tae Won Ha - http://taewon.de - @hataewon
// * See LICENSE
// */
//
//import Foundation
//
//class PreviewService {
//
//  fileprivate let empty: String
//  fileprivate let error: String
//  fileprivate let saveFirst: String
//
//  init() {
//    guard let emptyUrl = Bundle.main.url(forResource: "empty", withExtension: "html", subdirectory: "preview") else {
//      preconditionFailure("No empty.html!")
//    }
//
//    guard let errorUrl = Bundle.main.url(forResource: "error", withExtension: "html", subdirectory: "preview") else {
//      preconditionFailure("No error.html!")
//    }
//
//    guard let saveFirstUrl = Bundle.main.url(forResource: "save-first",
//                                             withExtension: "html",
//                                             subdirectory: "preview")
//      else {
//      preconditionFailure("No save-first.html!")
//    }
//
//    guard let emptyHtml = try? String(contentsOf: emptyUrl) else {
//      preconditionFailure("Error getting empty.html!")
//    }
//
//    guard let errorHtml = try? String(contentsOf: errorUrl) else {
//      preconditionFailure("Error getting error.html!")
//    }
//
//    guard let saveFirstHtml = try? String(contentsOf: saveFirstUrl) else {
//      preconditionFailure("Error getting save-first.html!")
//    }
//
//    self.empty = emptyHtml
//    self.error = errorHtml
//    self.saveFirst = saveFirstHtml
//  }
//
//  func baseUrl() -> URL {
//    return Bundle.main.resourceURL!.appendingPathComponent("preview")
//  }
//
//  func emptyHtml() -> String {
//    return self.empty
//  }
//
//  func errorHtml() -> String {
//    return self.error
//  }
//
//  func saveFirstHtml() -> String {
//    return self.saveFirst
//  }
//}
