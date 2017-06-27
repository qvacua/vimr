/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


typedef NS_ENUM(NSInteger, NeoVimServerMsgId) {
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
    NeoVimServerMsgIdStop,

    NeoVimServerMsgIdDirtyStatusChanged,
    NeoVimServerMsgIdCwdChanged,
    NeoVimServerMsgIdColorSchemeChanged,
    NeoVimServerMsgIdAutoCommandEvent,

#ifdef DEBUG
    NeoVimServerDebug1,
#endif
};

typedef NS_ENUM(NSInteger, NeoVimAgentMsgId) {
    NeoVimAgentMsgIdAgentReady = 0,
    NeoVimAgentMsgIdCommand,
    NeoVimAgentMsgIdCommandOutput,
    NeoVimAgentMsgIdInput,
    NeoVimAgentMsgIdInputMarked,
    NeoVimAgentMsgIdDelete,
    NeoVimAgentMsgIdResize,
    NeoVimAgentMsgIdSelectWindow,
    NeoVimAgentMsgIdScroll,
    NeoVimAgentMsgIdCursorGoto,
    NeoVimAgentMsgIdQuit,

    NeoVimAgentMsgIdGetDirtyDocs,
    NeoVimAgentMsgIdGetPwd,
    NeoVimAgentMsgIdGetEscapeFileNames,
    NeoVimAgentMsgIdGetBuffers,
    NeoVimAgentMsgIdGetTabs,

    NeoVimAgentMsgIdGetBoolOption,
    NeoVimAgentMsgIdSetBoolOption,

#ifdef DEBUG
    NeoVimAgentDebug1,
#endif
};
