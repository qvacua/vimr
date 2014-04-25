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
extern int qOpenQuicklySearchFieldMinWidth;

@interface VROpenQuicklyWindow : NSWindow

@property NSSearchField *searchField;
@property NSTableView *fileItemTableView;

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect;
- (void)reset;

#pragma mark NSWindow
- (BOOL)canBecomeKeyWindow;

@end
