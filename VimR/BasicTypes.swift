/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

protocol Copyable {

  associatedtype InstanceType

  func copy() -> InstanceType
}
