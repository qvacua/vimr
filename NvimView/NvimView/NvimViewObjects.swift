/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import NvimMsgPack

public struct NvimBuffer {

  public let apiBuffer: NvimApi.Buffer
  public let url: URL

  public let isDirty: Bool
  public let isCurrent: Bool
  public let isTransient: Bool
}
