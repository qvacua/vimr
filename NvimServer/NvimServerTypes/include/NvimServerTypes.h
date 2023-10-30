/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#ifndef NVIMSERVER_SHARED_TYPES_H
#define NVIMSERVER_SHARED_TYPES_H

#include <CoreFoundation/CoreFoundation.h>

#define NSInteger long
#define NSUInteger unsigned long

typedef CF_OPTIONS(NSUInteger, FontTrait) {
  FontTraitNone = 0,
  FontTraitItalic = (1 << 0),
  FontTraitBold = (1 << 1),
  FontTraitUnderline = (1 << 2),
  FontTraitUndercurl = (1 << 3)
};

typedef CF_ENUM(NSInteger, RenderDataType) {
  RenderDataTypeRawLine,
  RenderDataTypeGoto,
  RenderDataTypeScroll,
};

typedef CF_ENUM(NSInteger, NvimServerMsgId) {
  NvimServerMsgIdServerReady = 0,
  NvimServerMsgIdNvimReady,
  NvimServerMsgIdResize,
  NvimServerMsgIdClear,
  NvimServerMsgIdSetMenu,
  NvimServerMsgIdBusyStart,
  NvimServerMsgIdBusyStop,
  NvimServerMsgIdModeChange,
  NvimServerMsgIdModeInfoSet,
  NvimServerMsgIdBell,
  NvimServerMsgIdVisualBell,
  NvimServerMsgIdFlush,
  NvimServerMsgIdHighlightAttrs,
  NvimServerMsgIdSetTitle,
  NvimServerMsgIdStop,
  NvimServerMsgIdOptionSet,
  NvimServerMsgIdEvent,

  NvimServerMsgIdDirtyStatusChanged,
  NvimServerMsgIdCwdChanged,
  NvimServerMsgIdColorSchemeChanged,
  NvimServerMsgIdDefaultColorsChanged,
  NvimServerMsgIdAutoCommandEvent,
  NvimServerMsgIdRpcEventSubscribed,

  NvimServerMsgIdFatalError,

  NvimServerMsgIdDebug1,
};

typedef CF_ENUM(NSInteger, NvimServerFatalErrorCode) {
  NvimServerFatalErrorCodeLocalPort = 1,
  NvimServerFatalErrorCodeRemotePort,
};

typedef CF_ENUM(NSInteger, NvimBridgeMsgId) {
  NvimBridgeMsgIdAgentReady = 0,
  NvimBridgeMsgIdReadyForRpcEvents,
  NvimBridgeMsgIdDeleteInput,
  NvimBridgeMsgIdResize,
  NvimBridgeMsgIdScroll,

  NvimBridgeMsgIdFocusGained,

  NvimBridgeMsgIdDebug1,
};

#endif // NVIMSERVER_SHARED_TYPES_H
