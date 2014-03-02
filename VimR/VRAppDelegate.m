/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import "VRAppDelegate.h"


@implementation VRAppDelegate

#pragma mark NSApplicationDelegate
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // necessary MacVimFramework initialization {
    [MMUtils setKeyHandlingUserDefaults];
    [MMUtils setInitialUserDefaults];

    [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];
    // } necessary MacVimFramework initialization
}

@end
