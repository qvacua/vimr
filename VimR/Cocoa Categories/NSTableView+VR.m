/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "NSTableView+VR.h"


@implementation NSTableView (VR)

- (void)moveSelectionByDelta:(NSInteger)delta {
  NSInteger selectedRow = self.selectedRow;
  NSUInteger lastIndex = (NSUInteger) self.numberOfRows - 1;
  NSUInteger targetIndex;

  if (selectedRow + delta < 0) {
    targetIndex = 0;
  } else if (selectedRow + delta > lastIndex) {
    targetIndex = lastIndex;
  } else {
    targetIndex = (NSUInteger) (selectedRow + delta);
  }

  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:targetIndex] byExtendingSelection:NO];
  [self scrollRowToVisible:targetIndex];
}

- (void)moveSelectionToBottom {
  NSInteger targetIndex = self.numberOfRows - 1;
  if (targetIndex < 0) {
    return;
  }

  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:targetIndex] byExtendingSelection:NO];
  [self scrollRowToVisible:targetIndex];
}

- (void)moveSelectionToTop {
  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  [self scrollRowToVisible:0];
}

@end
