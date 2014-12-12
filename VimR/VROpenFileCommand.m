/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenFileCommand.h"
#import "VRAppDelegate.h"


@implementation VROpenFileCommand {

}

- (NSApplication *)app {
  return NSApp;
}

- (VRAppDelegate *)appDelegate {
  return (VRAppDelegate *) [self.app delegate];
}

@end
