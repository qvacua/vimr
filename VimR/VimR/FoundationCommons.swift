/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

extension URL {

  var direntType: UInt8 { (self as NSURL).direntType() }
}
