/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRMainWindow.h"
#import "VRMainWindowController.h"
#import "VRUtils.h"


@implementation VRMainWindow

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
  RETURN_NIL_WHEN_NOT_SELF
    
  [self setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

  return self;
}

- (id)windowController {
  return (VRMainWindowController *) [super windowController];
}

- (IBAction)performClose:(id)sender {
  [self.windowController performClose:sender];
}

- (void)zoom:(id)sender {
  // We shortcut the usual zooming behavior of NSWindow and provide custom zooming in the window controller.
  [self.windowController zoom:sender];
}

@end
