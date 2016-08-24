/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


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
  NeoVimServerMsgIdSuspend,
  NeoVimServerMsgIdSetTitle,
  NeoVimServerMsgIdSetIcon,
  NeoVimServerMsgIdDirtyStatusChanged,
  NeoVimServerMsgIdStop,

#ifdef DEBUG
  NeoVimServerDebug1,
#endif
};

typedef NS_ENUM(NSUInteger, NeoVimAgentMsgId) {
  NeoVimAgentMsgIdAgentReady = 0,
  NeoVimAgentMsgIdCommand,
  NeoVimAgentMsgIdInput,
  NeoVimAgentMsgIdInputMarked,
  NeoVimAgentMsgIdDelete,
  NeoVimAgentMsgIdResize,
  NeoVimAgentMsgIdQuit,

  NeoVimAgentMsgIdGetDirtyDocs,
  NeoVimAgentMsgIdGetEscapeFileNames,
  NeoVimAgentMsgIdGetBuffers,

#ifdef DEBUG
  NeoVimAgentDebug1,
#endif
};
