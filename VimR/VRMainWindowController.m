/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <PSMTabBarControl/PSMTabBarControl.h>
#import "VRMainWindowController.h"
#import "VRLog.h"


@implementation VRMainWindowController

#pragma mark NSWindowController
- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if (self == nil) {
        return nil;
    }

    _documents = [[NSMutableArray alloc] initWithCapacity:4];

    return self;
}

- (void)cleanup {
    log4Debug(@"cleanup");
}

- (void)dealloc {
    log4Debug(@"dealloc");
    [self.vimView removeFromSuperviewWithoutNeedingDisplay];
    [self.vimView cleanup];
}

#pragma mark MMVimControllerDelegate
- (void)vimController:(MMVimController *)controller handleShowDialogWithButtonTitles:(NSArray *)buttonTitles
                style:(NSAlertStyle)style message:(NSString *)message text:(NSString *)text
      textFieldString:(NSString *)string data:(NSData *)data {

    // 3 = don't save
    // 1 = save
    [self.vimController tellBackend:@[@3]];
}

- (void)vimController:(MMVimController *)controller showScrollbarWithIdentifier:(int32_t)identifier
                state:(BOOL)state data:(NSData *)data {

    [self.vimView showScrollbarWithIdentifier:identifier state:state];
}

- (void)vimController:(MMVimController *)controller setTextDimensionsWithRows:(int)rows columns:(int)columns
               isLive:(BOOL)live keepOnScreen:(BOOL)screen data:(NSData *)data {

    [self.vimView setDesiredRows:rows columns:columns];
}

- (void)vimController:(MMVimController *)controller openWindowWithData:(NSData *)data {
    self.window.acceptsMouseMovedEvents = YES; // Vim wants to have mouse move events

    self.vimView.frameSize = [self.window contentRectForFrameRect:self.window.frame].size;
    [self.window.contentView addSubview:self.vimView];

    [self.vimView addNewTabViewItem];
    [self.window makeFirstResponder:self.vimView.textView];
}

- (void)vimController:(MMVimController *)controller showTabBarWithData:(NSData *)data {
    [self.vimView.tabBarControl setHidden:NO];
    // Here we should resize and -position the Vim view...
}

- (void)vimController:(MMVimController *)controller setScrollbarThumbValue:(float)value proportion:(float)proportion
           identifier:(int32_t)identifier data:(NSData *)data {

    // Here we should resize and -position the Vim view...
}

- (void)vimController:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data {

}

- (void)vimController:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data {

}

#pragma mark NSWindowDelegate
- (void)windowDidBecomeMain:(NSNotification *)notification {
    [self.vimController sendMessage:GotFocusMsgID data:nil];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    [self.vimController sendMessage:LostFocusMsgID data:nil];
}

- (BOOL)windowShouldClose:(id)sender {
    // Don't close the window now; Instead let Vim decide whether to close the window or not.
    [self.vimController sendMessage:VimShouldCloseMsgID data:nil];
    return NO;
}

@end
