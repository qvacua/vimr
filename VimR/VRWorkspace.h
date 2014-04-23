/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class VRMainWindowController;
@class MMVimController;


@interface VRWorkspace : NSObject

@property NSURL *workingDirectory;
@property VRMainWindowController *mainWindowController;

#pragma mark Public
- (BOOL)hasModifiedBuffer;
- (void)setUpWithVimController:(MMVimController *)vimController;
- (void)cleanUpAndClose;

@end
