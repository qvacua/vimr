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
