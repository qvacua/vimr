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


extern int qOpenQuicklyWindowPadding;

@interface VROpenQuicklyWindow : NSWindow

@property NSSearchField *searchField;
@property NSProgressIndicator *progressIndicator;
@property NSTableView *fileItemTableView;

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect;
- (void)reset;

#pragma mark NSWindow
- (BOOL)canBecomeKeyWindow;

@end
