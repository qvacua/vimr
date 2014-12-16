/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenFilesCommand.h"
#import "VRAppDelegate.h"


@implementation VROpenFilesCommand

- (NSApplication *)app {
  return NSApp;
}

- (VRAppDelegate *)appDelegate {
  return (VRAppDelegate *) [self.app delegate];
}

- (NSArray *)fileUrls {
  return self.evaluatedArguments[@""];
}

@end
