/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxPack

public extension NvimView {
  struct Buffer: Equatable {
    public static func == (lhs: Buffer, rhs: Buffer) -> Bool {
      guard lhs.handle == rhs.handle else { return false }

      // Transient buffer active -> open a file -> the resulting buffer has the same handle,
      // but different URL
      return lhs.url == rhs.url
    }

    public let apiBuffer: RxNeovimApi.Buffer
    public let url: URL?
    public let type: String

    public let isDirty: Bool
    public let isCurrent: Bool
    public let isListed: Bool

    public var isTransient: Bool {
      if self.isDirty { return false }
      if self.url != nil { return false }

      return true
    }

    public var name: String? {
      if self.type == "quickfix" { return "Quickfix" }

      return self.url?.lastPathComponent
    }

    public var handle: Int { self.apiBuffer.handle }
  }

  struct Window {
    public let apiWindow: RxNeovimApi.Window
    public let buffer: Buffer
    public let isCurrentInTab: Bool

    public var handle: Int { self.apiWindow.handle }
  }

  struct Tabpage {
    public let apiTabpage: RxNeovimApi.Tabpage
    public let windows: [Window]
    public let isCurrent: Bool

    public var currentWindow: Window? { self.windows.first { $0.isCurrentInTab } }

    public var handle: Int { self.apiTabpage.handle }
  }
}
