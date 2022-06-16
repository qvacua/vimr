/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation

/// Reads the file at the given ``URL`` line by line.
/// The Unix line ending `LF` is used to determine lines.
/// Thus, it supports `LF` and `CRLF` files. It does not support the legacy Mac line ending `CR`.
public final class FileLineReader: Sequence {
  public static let defaultLineBufferCount = 1024

  public let url: URL

  public var lineBufferCount: Int
  public var encoding: String.Encoding

  /// - Parameters:
  ///   - url: URL of the file.
  ///   - encoding: Encoding of the file. It's mutable.
  ///     After mutating, the next iterator will use the new value.
  ///   - lineBufferCount: The initial size of the buffer for reading lines. It's mutable.
  ///     After mutating, the next iterator will use the new value.
  ///     The default is ``FileLineReader/defaultLineBufferCount``.
  public init(url: URL, encoding: String.Encoding, lineBufferCount: Int = defaultLineBufferCount) {
    self.lineBufferCount = lineBufferCount
    self.url = url
    self.encoding = encoding
  }

  public func makeIterator() -> AnyIterator<String> {
    guard let file = fopen(url.path, "r") else { return AnyIterator { nil } }

    let iterator = LfLineIterator(
      file: file,
      encoding: self.encoding,
      lineBufferCount: self.lineBufferCount
    )
    return AnyIterator { iterator.next() }
  }
}

private class LfLineIterator: IteratorProtocol {
  init(
    file: UnsafeMutablePointer<FILE>,
    encoding: String.Encoding,
    lineBufferCount: Int
  ) {
    self.file = file
    self.encoding = encoding
    self.buffer = Array(repeating: 0, count: lineBufferCount)
  }

  deinit { fclose(self.file) }

  func next() -> String? {
    var readCharCount = 0
    while true {
      let nextChar = getc(self.file)

      if nextChar == EOF {
        if readCharCount == 0 { return nil }
        return String(
          data: Data(
            bytesNoCopy: self.buffer[0..<readCharCount].unsafeMutableRawPointer,
            count: readCharCount,
            deallocator: .none
          ), encoding: self.encoding
        )
      }

      if readCharCount >= self.buffer.count {
        // Array.append()
        // https://developer.apple.com/documentation/swift/array/3126937-append
        // "Complexity: O(1) on average, over many calls to append(_:) on the same array."
        self.buffer.append(UInt8(nextChar))
      } else {
        self.buffer[readCharCount] = UInt8(nextChar)
      }
      readCharCount += 1

      if nextChar == Self.unixLineEnding {
        return String(
          data: Data(
            bytesNoCopy: self.buffer[0..<readCharCount].unsafeMutableRawPointer,
            count: readCharCount,
            deallocator: .none
          ), encoding: self.encoding
        )
      }
    }
  }

  private let encoding: String.Encoding
  private var buffer: [UInt8]
  private let file: UnsafeMutablePointer<FILE>

  private static let unixLineEnding = "\n".utf8.first!
}

private extension ArraySlice {
  @inline(__always)
  var unsafeMutableRawPointer: UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(mutating: self.withUnsafeBytes { $0.baseAddress! })
  }
}
