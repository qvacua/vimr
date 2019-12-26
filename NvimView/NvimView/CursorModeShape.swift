/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

// Keep in sync with ModeShape enum in cursor_shape.h.
public enum CursorModeShape: UInt {

  case normal = 0
  case visual
  case insert
  case replace
  case cmdlineNormal
  case cmdlineInsert
  case cmdlineReplace
  case operatorPending
  case visualExclusive
  case onCmdline
  case onStatusLine
  case draggingStatusLine
  case onVerticalSepLine
  case draggingVerticalSepLine
  case more
  case moreLastLine
  case showingMatchingParen
  case termFocus
  case count
}
