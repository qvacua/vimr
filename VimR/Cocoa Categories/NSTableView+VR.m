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

- (NSRange)visibleRange {
  NSRect visibleRect = [self visibleRect];
  return [self rowsInRect:visibleRect];
}

- (void)scrollDownOneLine {
  NSRange vr = [self visibleRange];
  NSInteger maxIndex = self.numberOfRows - 1;
  NSUInteger mustBeVisible = vr.location + vr.length;
  if (mustBeVisible <= maxIndex ) {
    // So we will actually scroll down
    NSUInteger willBeSelected = MAX(self.selectedRow, vr.location + 1);
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:willBeSelected] byExtendingSelection:NO];
    [self scrollRowToVisible:mustBeVisible];
  }
}

- (void)scrollUpOneLine {
  NSRange vr = [self visibleRange];
  NSInteger mustBeVisible = vr.location - 1;
  if (mustBeVisible >= 0) {
    // So we will actually scroll up
    NSUInteger willBeSelected = MIN(self.selectedRow , vr.location + vr.length - 2);
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:willBeSelected] byExtendingSelection:NO];
    [self scrollRowToVisible:mustBeVisible];
  }
}

- (void)scrollDownOneScreen {
  NSRange vr = [self visibleRange];
  NSInteger maxIndex = self.numberOfRows - 1;
  NSUInteger mustBeVisible = MIN(vr.location + 2*vr.length - 1, maxIndex);

  NSUInteger willBeSelected = mustBeVisible - vr.length + 1;
  if (willBeSelected > self.selectedRow) {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:willBeSelected] byExtendingSelection:NO];
  }
  [self scrollRowToVisible:mustBeVisible];
}

- (void)scrollUpOneScreen {
  NSRange vr = [self visibleRange];
  // The difference in the second argument here might become negative. To avoid
  // underflows of NSUInteger, we cast to NSInteger here.
  NSInteger mustBeVisible = MAX(0, (NSInteger)vr.location - (NSInteger)vr.length);

  NSUInteger willBeSelected = mustBeVisible + vr.length - 1;
  if (willBeSelected < self.selectedRow) {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:willBeSelected] byExtendingSelection:NO];
  }
  [self scrollRowToVisible:mustBeVisible];
}

@end
