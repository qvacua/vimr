/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@interface NSTableView (VR)

- (void)moveSelectionByDelta:(NSInteger)delta;
- (void)moveSelectionToBottom;
- (void)moveSelectionToTop;
- (void)scrollDownOneLine;
- (void)scrollUpOneLine;
- (void)scrollDownOneScreen;
- (void)scrollUpOneScreen;

@end
