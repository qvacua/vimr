/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileLogger {

  enum Level: String {

    case `default` = "DEFAULT"
    case info = "INFO"
    case debug = "DEBUG"
    case error = "ERROR"
    case fault = "FAULT"
  }

  let uuid = UUID().uuidString
  let name: String

  let shouldLogDebug: Bool

  init<T>(as name: T, with fileUrl: URL) {
    #if DEBUG
    self.shouldLogDebug = true
    #else
    self.shouldLogDebug = false
    #endif

    switch name {
    case let str as String: self.name = str
    default: self.name = String(describing: name)
    }

    guard fileUrl.isFileURL else {
      preconditionFailure("\(fileUrl) must be a file URL!")
    }

    self.queue = DispatchQueue(label: self.uuid, qos: .background)

    self.fileUrl = fileUrl
    self.setupFileHandle(at: fileUrl)

    self.logDateFormatter.dateFormat = "dd HH:mm:SSS"
    self.fileDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-SSS"
  }

  fileprivate func setupFileHandle(at fileUrl: URL) {
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

  deinit {
    self.fileHandle.closeFile()
  }

  func mark(file: String = #file, line: Int = #line, function: String = #function) {
    guard self.shouldLogDebug else {
      return
    }

    self.log("", level: .debug, file: file, line: line, function: function)
  }

  func `default`<T>(_ message: @escaping @autoclosure () -> T,
                    file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .default, file: file, line: line, function: function)
  }

  func info<T>(_ message: @escaping @autoclosure () -> T,
               file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .info, file: file, line: line, function: function)
  }

  func debug<T>(_ message: @escaping @autoclosure () -> T,
                file: String = #file, line: Int = #line, function: String = #function) {

    guard self.shouldLogDebug else {
      return
    }

    self.log(message, level: .debug, file: file, line: line, function: function)
  }

  func error<T>(_ message: @escaping @autoclosure () -> T,
                file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .error, file: file, line: line, function: function)
  }

  func fault<T>(_ message: @escaping @autoclosure () -> T,
                file: String = #file, line: Int = #line, function: String = #function) {

    self.log(message, level: .fault, file: file, line: line, function: function)
  }

  func log<T>(_ message: @escaping @autoclosure () -> T, level: Level = .default,
              file: String = #file, line: Int = #line, function: String = #function) {

    self.queue.async {
      let timestamp = self.logDateFormatter.string(from: Date())
      let strMsg = self.string(from: message())

      let logMsg = "\(timestamp) \(self.name) \(function) - \(strMsg)"
      let data = "[\(level.rawValue)] \(logMsg)\n".data(using: .utf8) ?? conversionError

      self.fileHandle.write(data)

      if self.fileHandle.offsetInFile >= maxFileSize {
        self.archiveLogFile()
      }
    }
  }

  fileprivate func archiveLogFile() {
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

  fileprivate func string<T>(from obj: T) -> String {
    switch obj {
    case let str as String: return str
    case let convertible as CustomStringConvertible: return convertible.description
    case let convertible as CustomDebugStringConvertible: return convertible.debugDescription
    default: return String(describing: obj)
    }
  }

  fileprivate let fileUrl: URL
  fileprivate var fileHandle = FileHandle.standardOutput
  fileprivate let logDateFormatter = DateFormatter()
  fileprivate let fileDateFormatter = DateFormatter()
  fileprivate let queue: DispatchQueue
}

fileprivate let conversionError = "[ERROR] Could not convert log msg to Data!".data(using: .utf8)!
fileprivate let fileManager = FileManager.default
fileprivate let maxFileSize: UInt64 = 1 * 1024 * 1024
