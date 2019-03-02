/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

let stdoutLogger = LogContext.stdoutLogger(as: "NvimView")
let logger = LogContext.fileLogger(
  as: "NvimView", with: URL(fileURLWithPath: "/tmp/nvv.log")
)

class LogContext {

  enum Level: String {

    case `default` = "DEFAULT"
    case info = "INFO"
    case trace = "TRACE"
    case debug = "DEBUG"
    case error = "ERROR"
    case fault = "FAULT"
  }

  static func stdoutLogger<T>(as name: T, shouldLogDebug: Bool? = nil) -> Logger {
    return Logger(as: name, with: self.stdoutAppender, shouldLogDebug: shouldLogDebug)
  }

  static func fileLogger<T>(as name: T, with url: URL, shouldLogDebug: Bool? = nil) -> Logger {
    let appender = self.appenderManager.requestFileAppender(for: url)
    return Logger(as: name, with: appender, shouldLogDebug: shouldLogDebug)
  }

  private static let stdoutAppender = StdoutAppender()
  private static let appenderManager = FileAppenderManager()
}

private class FileAppenderManager {

  fileprivate func requestFileAppender(`for` url: URL) -> FileAppender {
    self.lock.lock()
    defer { self.lock.unlock() }

    if let fileAppender = self.fileAppenders[url] {
      return fileAppender
    }

    let fileAppender = FileAppender(with: url, manager: self)
    self.fileAppenders[url] = fileAppender

    return fileAppender
  }

  fileprivate func deregisterFileAppender(`for` url: URL) {
    self.lock.lock()
    defer { self.lock.unlock() }

    self.fileAppenders.removeValue(forKey: url)
  }

  private let lock = NSRecursiveLock()

  private var fileAppenders: [URL: FileAppender] = [:]
}

class Logger {

  let uuid = UUID().uuidString
  let name: String

  var shouldLogDebug: Bool

  init<T>(as name: T, with appender: Appender, shouldLogDebug: Bool? = nil) {
    if let debug = shouldLogDebug {
      self.shouldLogDebug = debug
    } else {
#if DEBUG
      self.shouldLogDebug = true
#else
      self.shouldLogDebug = false
#endif
    }

    switch name {
    case let str as String: self.name = str
    default: self.name = String(describing: name)
    }

    self.logDateFormatter.dateFormat = "dd HH:mm:ss.SSS"
    self.appender = appender
  }

  func hr(file: String = #file, line: Int = #line, function: String = #function) {
    self.log("----------", level: .debug, file: file, line: line, function: function)
  }

  func mark(file: String = #file, line: Int = #line, function: String = #function) {
    self.log("", level: .debug, file: file, line: line, function: function)
  }

  func `default`<T>(_ message: T,
                    file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .default, file: file, line: line, function: function)
  }

  func info<T>(_ message: T,
               file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .info, file: file, line: line, function: function)
  }

  func debug<T>(_ message: T,
                file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .debug, file: file, line: line, function: function)
  }

  func trace<T>(_ message: T,
                file: String = #file, line: Int = #line, function: String = #function) {

#if TRACE
    self.log(message, level: .trace, file: file, line: line, function: function)
#endif
  }

  func error<T>(_ message: T,
                file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .error, file: file, line: line, function: function)
  }

  func fault<T>(_ message: T,
                file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .fault, file: file, line: line, function: function)
  }

  func log<T>(_ message: T, level: LogContext.Level = .default,
              file: String = #file, line: Int = #line, function: String = #function) {

    guard self.shouldLogDebug else {
      return
    }

    let timestamp = self.logDateFormatter.string(from: Date())
    let strMsg = self.string(from: message)

    let logMsg = "\(timestamp) \(self.name) \(function) \(strMsg)"
    let data = "[\(level.rawValue)] \(logMsg)\n".data(using: .utf8) ?? conversionErrorMsg
    self.appender.write(data)
  }

  private func string<T>(from obj: T) -> String {
    switch obj {
    case let str as String: return str
    case let convertible as CustomStringConvertible: return convertible.description
    case let convertible as CustomDebugStringConvertible: return convertible.debugDescription
    default: return String(describing: obj)
    }
  }

  private let appender: Appender
  private let logDateFormatter = DateFormatter()
}

protocol Appender {

  func write(_ data: Data)
}

private class StdoutAppender: Appender {

  init() {
    self.handle = .standardOutput
  }

  deinit {
    self.handle.closeFile()
  }

  func write(_ data: Data) {
    self.queue.async {
      self.handle.write(data)
    }
  }

  private let handle: FileHandle

  private let queue = DispatchQueue(label: String(describing: StdoutAppender.self), qos: .background)
}

private class FileAppender: Appender {

  init(with fileUrl: URL, manager: FileAppenderManager) {
    guard fileUrl.isFileURL else {
      preconditionFailure("\(fileUrl) must be a file URL!")
    }

    self.queue = DispatchQueue(label: self.uuid, qos: .background)
    self.fileUrl = fileUrl
    self.manager = manager
    self.fileDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-SSS"
    self.setupFileHandle(at: fileUrl)
  }

  deinit {
    self.fileHandle.closeFile()
    self.manager?.deregisterFileAppender(for: self.fileUrl)
  }

  func write(_ data: Data) {
    queue.async {
      self.fileHandle.write(data)

      if self.fileHandle.offsetInFile >= maxFileSize {
        self.archiveLogFile()
      }
    }
  }

  private let uuid = UUID().uuidString

  private let fileUrl: URL
  private weak var manager: FileAppenderManager?
  private var fileHandle = FileHandle.standardOutput
  private let fileDateFormatter = DateFormatter()

  private let queue: DispatchQueue

  private func setupFileHandle(at fileUrl: URL) {
    if !fileManager.fileExists(atPath: fileUrl.path) {
      fileManager.createFile(atPath: fileUrl.path, contents: nil)
    }

    if let fileHandle = try? FileHandle(forWritingTo: fileUrl) {
      self.fileHandle = fileHandle
      self.fileHandle.seekToEndOfFile()
    } else {
      NSLog("[ERROR] Could not get handle for \(fileUrl), defaulting to STDOUT")
      self.fileHandle = FileHandle.standardOutput
    }
  }

  private func archiveLogFile() {
    self.fileHandle.closeFile()

    do {
      let fileTimestamp = self.fileDateFormatter.string(from: Date())
      let fileName = self.fileUrl.deletingPathExtension().lastPathComponent
      let archiveFileName = "\(fileName)-\(fileTimestamp).\(self.fileUrl.pathExtension)"
      let archiveFileUrl = self.fileUrl
        .deletingLastPathComponent().appendingPathComponent(archiveFileName)

      try fileManager.moveItem(at: self.fileUrl, to: archiveFileUrl)
    } catch let error as NSError {
      NSLog("[ERROR] Could not archive log file: \(error)")
    }

    self.setupFileHandle(at: self.fileUrl)
  }
}

private let conversionErrorMsg = "[ERROR] Could not convert log msg to Data!".data(using: .utf8)!
private let fileManager = FileManager.default
private let maxFileSize: UInt64 = 4 * 1024 * 1024
