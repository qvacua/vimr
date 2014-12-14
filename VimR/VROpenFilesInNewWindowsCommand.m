/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenFilesInNewWindowsCommand.h"
#import "VRDefaultLogSetting.h"
#import "VRAppDelegate.h"


@implementation VROpenFilesInNewWindowsCommand

- (id)performDefaultImplementation {
  NSArray *fileUrls = self.fileUrls;

  DDLogDebug(@"VimR OSA: Calling open file in new windows command with args: %@", fileUrls);
  for (NSURL *url in fileUrls) {
    [self.appDelegate application:self.app openFile:url.path];
  }

  return nil;
}

@end
