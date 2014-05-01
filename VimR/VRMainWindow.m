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


@implementation VRMainWindow

#pragma mark NSWindow
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
