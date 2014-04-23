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


extern int qOpenQuicklyWindowWidth;

@interface VROpenQuicklyWindowController : NSWindowController <TBBean, NSWindowDelegate, NSTextFieldDelegate>

@property (weak) VRFileItemManager *fileItemManager;

#pragma mark Public
- (void)showForWindow:(NSWindow *)contentRect url:(NSURL *)targetUrl;

#pragma mark NSObject
- (id)init;

#pragma mark NSWindowDelegate
- (void)windowDidResignMain:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;

@end
