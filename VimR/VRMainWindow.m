/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRMainWindow.h"


@implementation VRMainWindow

- (IBAction)performClose:(id)sender {
  if ([self.windowController respondsToSelector:@selector(performClose:)]) {
    [self.windowController performClose:sender];
    return;
  }

  [super performClose:sender];
}

@end
