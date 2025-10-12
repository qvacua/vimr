/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

public extension Logger {
  func error(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: @autoclosure () -> some Any
  ) {
    let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg())"
    self.log(level: .error, "\(message)")
  }

  func fault(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: @autoclosure () -> some Any
  ) {
    let message = "[\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg())"
    self.log(level: .fault, "\(message)")
  }
}

public struct DevLogger: Sendable {
  public static let shared = DevLogger(mode: .file)

  public enum Mode {
    case os
    case file
    case noop
  }

  private let appender: LogAppender

  public init(mode: Mode) {
    let subsystem = Bundle.main.bundleIdentifier ?? "app-\(UUID().uuidString)"
    let category = "development"

    #if DEBUG || TRACE
      switch mode {
      case .os:
        self.appender = OsAppender(subsystem: subsystem, category: category)
      case .file:
        self.appender = FileAppender(subsystem: subsystem, category: category) ?? OsAppender(
          subsystem: subsystem,
          category: category
        )
      case .noop:
        self.appender = NoopAppender()
      }
    #else
      self.appender = NoopAppender()
    #endif
  }

  public func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    #if DEBUG
      self.appender.debug(file: file, function: function, line: line, "MARK")
    #endif
  }

  public func debug(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: @autoclosure () -> some Any
  ) {
    #if DEBUG
      self.appender.debug(file: file, function: function, line: line, "\(msg())")
    #endif
  }

  public func trace(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ msg: @autoclosure () -> some Any
  ) {
    #if TRACE
      self.appender.trace(file: file, function: function, line: line, "\(msg())")
    #endif
  }

  protocol LogAppender: Sendable {
    func debug(file: String, function: String, line: Int, _ msg: String)
    func trace(file: String, function: String, line: Int, _ msg: String)
  }

  struct NoopAppender: LogAppender {
    func debug(file: String, function: String, line: Int, _: String) {}
    func trace(file: String, function: String, line: Int, _: String) {}
  }

  // We sync using a DispatchQueue
  class FileAppender: LogAppender, @unchecked Sendable {
    static let fileSizeLimit = 1024 * 1024 * 10 // 10MB

    private let logger: Logger

    private let queue: DispatchQueue

    private let logDir: URL
    private let dateStr: String

    private var logFileNumber = 0
    private var fileHandle: FileHandle
    private var estimatedFileSize = UInt64(0)

    private let timeFormatter = DateFormatter()

    init?(subsystem: String, category: String) {
      self.logger = Logger(subsystem: subsystem, category: "info")

      self.queue = DispatchQueue(label: "\(subsystem).\(category)-queue", qos: .utility)

      let formatter = DateFormatter()
      formatter.dateFormat = "yyyyMMdd.HHmmss"
      self.dateStr = formatter.string(from: Date())

      self.timeFormatter.dateFormat = "HH:mm:ss.SSS"

      let tempDir = FileManager.default.temporaryDirectory
      self.logDir = tempDir.appendingPathComponent("\(subsystem).\(category)")

      do {
        try FileManager.default.createDirectory(at: self.logDir, withIntermediateDirectories: true)
        let logFile = self.logDir
          .appendingPathComponent("\(self.dateStr)-\(self.logFileNumber).log")
        if !FileManager.default.fileExists(atPath: logFile.path) {
          FileManager.default.createFile(atPath: logFile.path, contents: nil)
        }

        self.fileHandle = try FileHandle(forWritingTo: logFile)
        self.estimatedFileSize = try self.fileHandle.seekToEnd()

        self.logger.info("Logging to \(logFile)")
      } catch {
        self.logger.error("Error creating FileAppender!")
        return nil
      }
    }

    deinit {
      do {
        try self.fileHandle.close()
      } catch {
        self.logger.error("Could not close file handle: \(error)")
      }
    }

    // Only call when inside the queue
    private func checkFileSizeAndRotate() {
      guard self.estimatedFileSize >= Self.fileSizeLimit else {
        return
      }

      self.logFileNumber += 1
      let logFile = self.logDir
        .appendingPathComponent("\(self.dateStr)-\(self.logFileNumber).log")
      if !FileManager.default.fileExists(atPath: logFile.path) {
        FileManager.default.createFile(atPath: logFile.path, contents: nil)
      }

      do {
        let newFileHandle = try FileHandle(forWritingTo: logFile)
        self.estimatedFileSize = try newFileHandle.seekToEnd()

        try self.fileHandle.close()
        self.fileHandle = newFileHandle

        self.logger.info("Rotated: logging to \(logFile)")
      } catch {
        self.logger
          .error("""
          Rotation to \(logFile) failed: \(error).
          Logging to the current log file, maybe rotation will succeed when logging next.
          """)
      }
    }

    private func write(
      file f: String,
      function fn: String,
      line l: Int,
      prefix: String,
      _ msg: String
    ) {
      let now = Date()
      self.queue.async {
        let t = self.timeFormatter.string(from: now)
        let str = "\(t) [\(prefix)] [\((f as NSString).lastPathComponent) - \(fn):\(l)] \(msg)\n"
        let data = Data(str.utf8)

        do {
          try self.fileHandle.write(contentsOf: data)
          self.estimatedFileSize += UInt64(data.count)
        } catch {
          self.logger.error("""
          Couldn't log to file: err: \(error)
          Msg: \(str.dropLast())
          """)
          return
        }

        self.checkFileSizeAndRotate()
      }
    }

    func debug(file: String, function: String, line: Int, _ msg: String) {
      self.write(file: file, function: function, line: line, prefix: "DEBUG", msg)
    }

    func trace(file: String, function: String, line: Int, _ msg: String) {
      self.write(file: file, function: function, line: line, prefix: "TRACE", msg)
    }
  }

  struct OsAppender: LogAppender {
    private let logger: Logger

    init(subsystem: String, category: String) {
      self.logger = Logger(subsystem: subsystem, category: category)
    }

    func debug(file: String, function: String, line: Int, _ msg: String) {
      self.logger.log(
        level: .debug,
        "[DEBUG] [\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
      )
    }

    func trace(file: String, function: String, line: Int, _ msg: String) {
      self.logger.log(
        level: .debug,
        "[TRACE] [\((file as NSString).lastPathComponent) - \(function):\(line)] \(msg)"
      )
    }
  }
}
