/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import NvimMsgPack

extension NvimView {

  public struct Buffer: Equatable {

    public static func ==(lhs: Buffer, rhs: Buffer) -> Bool {
      return lhs.handle == rhs.handle
    }

    public let apiBuffer: NvimApi.Buffer
    public let url: URL?

    public let isReadOnly: Bool
    public let isDirty: Bool
    public let isCurrent: Bool

    public var isTransient: Bool {
      if self.isDirty {
        return false
      }

      if self.url != nil {
        return false
      }

      return true
    }

    public var name: String? {
      return self.url?.lastPathComponent
    }

    public var handle: Int {
      return self.apiBuffer.handle
    }
  }

  public struct Window {

    public let apiWindow: NvimApi.Window
    public let buffer: Buffer
    public let isCurrentInTab: Bool

    public var handle: Int {
      return self.apiWindow.handle
    }
  }

  public struct Tabpage {

    public let apiTabpage: NvimApi.Tabpage
    public let windows: [Window]
    public let isCurrent: Bool

    public var currentWindow: Window? {
      return self.windows.first { $0.isCurrentInTab }
    }

    public var handle: Int {
      return self.apiTabpage.handle
    }
  }
}
