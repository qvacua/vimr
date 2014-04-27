/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <TBCacao/TBCacao.h>


@class VRFileItemManager;
@class VRMainWindowController;


extern int qOpenQuicklyWindowWidth;


@interface VROpenQuicklyWindowController : NSWindowController <
    TBBean, TBInitializingBean,
    NSWindowDelegate,
    NSTextFieldDelegate,
    NSTableViewDataSource, NSTableViewDelegate>

@property (weak) VRFileItemManager *fileItemManager;
@property (weak) NSNotificationCenter *notificationCenter;

#pragma mark Public
- (void)showForWindowController:(VRMainWindowController *)windowController;
- (void)cleanUp;

#pragma mark NSObject
- (IBAction)secondDebugAction:(id)sender;
- (id)init;


- (void)controlTextDidChange:(NSNotification *)obj;
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector;

#pragma mark NSWindowDelegate
- (void)windowDidResignMain:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;

@end
