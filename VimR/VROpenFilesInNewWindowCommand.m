/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenFilesInNewWindowCommand.h"
#import "VRDefaultLogSetting.h"
#import "VRAppDelegate.h"
#import "NSArray+VR.h"
#import "VRWorkspaceController.h"


@implementation VROpenFilesInNewWindowCommand

- (id)performDefaultImplementation {
  NSArray *fileUrls = self.fileUrls;

  DDLogDebug(@"VimR OSA: Calling open file in new window command with args: %@", fileUrls);

  if (fileUrls.isEmpty) {
    DDLogDebug(@"VimR OSA: Opening an untitled window because there was no given file");
    [self.appDelegate.workspaceController newWorkspace];
    return nil;
  }

  [self.appDelegate application:self.app openFiles:fileUrls];
  return nil;
}

@end
