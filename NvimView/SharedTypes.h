/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, FontTrait) {
  FontTraitNone = 0,
  FontTraitItalic = (1 << 0),
  FontTraitBold = (1 << 1),
  FontTraitUnderline = (1 << 2),
  FontTraitUndercurl = (1 << 3)
};

// Keep in sync with ModeShape enum in cursor_shape.h.
typedef NS_ENUM(NSUInteger, CursorModeShape) {
  CursorModeShapeNormal = 0,
  CursorModeShapeVisual = 1,
  CursorModeShapeInsert = 2,
  CursorModeShapeReplace = 3,
  CursorModeShapeCmdline = 4,
  CursorModeShapeCmdlineInsert = 5,
  CursorModeShapeCmdlineReplace = 6,
  CursorModeShapeOperatorPending = 7,
  CursorModeShapeVisualExclusive = 8,
  CursorModeShapeOnCmdline = 9,
  CursorModeShapeOnStatusLine = 10,
  CursorModeShapeDraggingStatusLine = 11,
  CursorModeShapeOnVerticalSepLine = 12,
  CursorModeShapeDraggingVerticalSepLine = 13,
  CursorModeShapeMore = 14,
  CursorModeShapeMoreLastLine = 15,
  CursorModeShapeShowingMatchingParen = 16,
  CursorModeShapeTermFocus = 17,
  CursorModeShapeCount = 18,
};

typedef NS_ENUM(NSInteger, RenderDataType) {
  RenderDataTypeRawLine,
  RenderDataTypeGoto,
  RenderDataTypeScroll,
};

typedef NS_ENUM(NSInteger, NvimServerMsgId) {
  NvimServerMsgIdServerReady = 0,
  NvimServerMsgIdNvimReady,
  NvimServerMsgIdResize,
  NvimServerMsgIdClear,
  NvimServerMsgIdSetMenu,
  NvimServerMsgIdBusyStart,
  NvimServerMsgIdBusyStop,
  NvimServerMsgIdModeChange,
  NvimServerMsgIdUnmark,
  NvimServerMsgIdBell,
  NvimServerMsgIdVisualBell,
  NvimServerMsgIdFlush,
  NvimServerMsgIdHighlightAttrs,
  NvimServerMsgIdSetTitle,
  NvimServerMsgIdStop,
  NvimServerMsgIdOptionSet,
  
  NvimServerMsgIdDirtyStatusChanged,
  NvimServerMsgIdCwdChanged,
  NvimServerMsgIdColorSchemeChanged,
  NvimServerMsgIdDefaultColorsChanged,
  NvimServerMsgIdAutoCommandEvent,
  
  NvimServerMsgIdDebug1,
};

typedef NS_ENUM(NSInteger, NvimBridgeMsgId) {
  NvimBridgeMsgIdAgentReady = 0,
  NvimBridgeMsgIdInput,
  NvimBridgeMsgIdInputMarked,
  NvimBridgeMsgIdDelete,
  NvimBridgeMsgIdResize,
  NvimBridgeMsgIdScroll,
  
  NvimBridgeMsgIdFocusGained,
  
  NvimBridgeMsgIdDebug1,
};
