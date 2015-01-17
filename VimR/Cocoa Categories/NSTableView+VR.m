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

@end
