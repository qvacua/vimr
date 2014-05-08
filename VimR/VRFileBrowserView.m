/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFileBrowserView.h"


@implementation VRFileBrowserView {

}

- (void)drawRect:(NSRect)dirtyRect {
  [[NSColor yellowColor] set];
  NSRectFill(dirtyRect);
}

- (BOOL)mouseDownCanMoveWindow {
  // I dunno why, but if we don't override this, then the window title has the inactive appearance and the drag in the
  // VRWorkspaceView in combination with the vim view does not work correctly. To override -isOpaque does not suffice.
  return NO;
}

@end
