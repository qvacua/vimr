/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, NeoVimServerMsgId) {
    NeoVimServerMsgIdServerReady = 0,
    NeoVimServerMsgIdNeoVimReady,
    NeoVimServerMsgIdResize,
    NeoVimServerMsgIdClear,
    NeoVimServerMsgIdEolClear,
    NeoVimServerMsgIdSetMenu,
    NeoVimServerMsgIdBusyStart,
    NeoVimServerMsgIdBusyStop,
    NeoVimServerMsgIdMouseOn,
    NeoVimServerMsgIdMouseOff,
    NeoVimServerMsgIdModeChange,
    NeoVimServerMsgIdSetScrollRegion,
    NeoVimServerMsgIdScroll,
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
    NeoVimAgentMsgIdInput,
    NeoVimAgentMsgIdInputMarked,
    NeoVimAgentMsgIdDelete,
    NeoVimAgentMsgIdResize,
    NeoVimAgentMsgIdScroll,

    NeoVimAgentMsgIdGetEscapeFileNames,

    NeoVimAgentMsgIdFocusGained,

#ifdef DEBUG
    NeoVimAgentDebug1,
#endif
};
