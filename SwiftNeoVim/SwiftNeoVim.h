/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>

//! Project version number for SwiftNeoVim.
FOUNDATION_EXPORT double SwiftNeoVimVersionNumber;

//! Project version string for SwiftNeoVim.
FOUNDATION_EXPORT const unsigned char SwiftNeoVimVersionString[];

#import <SwiftNeoVim/NeoVimUiBridgeProtocol.h>
// TODO: this header should not be public, but we cannot use a bridging header in a framework.
#import <SwiftNeoVim/TextDrawer.h>
#import <SwiftNeoVim/NeoVimAgent.h>
#import <SwiftNeoVim/NeoVimMsgIds.h>
#import <SwiftNeoVim/NeoVimBuffer.h>
#import <SwiftNeoVim/NeoVimTab.h>
#import <SwiftNeoVim/NeoVimWindow.h>
#import <SwiftNeoVim/NeoVimAutoCommandEvent.generated.h>
