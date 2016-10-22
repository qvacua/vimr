/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


typedef NS_ENUM(NSUInteger, NeoVimServerMsgId) {
  NeoVimServerMsgIdServerReady = 0,
  NeoVimServerMsgIdNeoVimReady,
  NeoVimServerMsgIdResize,
  NeoVimServerMsgIdClear,
  NeoVimServerMsgIdEolClear,
  NeoVimServerMsgIdSetPosition,
  NeoVimServerMsgIdSetMenu,
  NeoVimServerMsgIdBusyStart,
  NeoVimServerMsgIdBusyStop,
  NeoVimServerMsgIdMouseOn,
  NeoVimServerMsgIdMouseOff,
  NeoVimServerMsgIdModeChange,
  NeoVimServerMsgIdSetScrollRegion,
  NeoVimServerMsgIdScroll,
  NeoVimServerMsgIdSetHighlightAttributes,
  NeoVimServerMsgIdPut,
  NeoVimServerMsgIdPutMarked,
  NeoVimServerMsgIdUnmark,
  NeoVimServerMsgIdBell,
  NeoVimServerMsgIdVisualBell,
  NeoVimServerMsgIdFlush,
  NeoVimServerMsgIdSetForeground,
  NeoVimServerMsgIdSetBackground,
  NeoVimServerMsgIdSetSpecial,
  NeoVimServerMsgIdSetTitle,
  NeoVimServerMsgIdSetIcon,
  NeoVimServerMsgIdDirtyStatusChanged,
  NeoVimServerMsgIdCwdChanged,
  NeoVimServerMsgIdCommandOutputResult,
  NeoVimServerMsgIdStop,

#ifdef DEBUG
  NeoVimServerDebug1,
#endif
};

typedef NS_ENUM(NSUInteger, NeoVimAgentMsgId) {
  NeoVimAgentMsgIdAgentReady = 0,
  NeoVimAgentMsgIdCommand,
  NeoVimAgentMsgIdCommandOutput,
  NeoVimAgentMsgIdInput,
  NeoVimAgentMsgIdInputMarked,
  NeoVimAgentMsgIdDelete,
  NeoVimAgentMsgIdResize,
  NeoVimAgentMsgIdQuit,

  NeoVimAgentMsgIdGetDirtyDocs,
  NeoVimAgentMsgIdGetEscapeFileNames,
  NeoVimAgentMsgIdGetBuffers,
  NeoVimAgentMsgIdGetTabs,

#ifdef DEBUG
  NeoVimAgentDebug1,
#endif
};
