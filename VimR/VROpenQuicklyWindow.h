/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class VROpenQuicklyWindowController;
@class VRInactiveTableView;


extern int qOpenQuicklyWindowPadding;

@interface VROpenQuicklyWindow : NSWindow

@property NSSearchField *searchField;
@property NSProgressIndicator *progressIndicator;
@property VRInactiveTableView *fileItemTableView;
@property NSTextField *itemCountTextField;

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect;
- (void)reset;

#pragma mark NSWindow
- (BOOL)canBecomeKeyWindow;

@end
