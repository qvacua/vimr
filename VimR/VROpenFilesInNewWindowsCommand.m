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
#import "VRWorkspaceController.h"
#import "NSArray+VR.h"


@implementation VROpenFilesInNewWindowsCommand

- (id)performDefaultImplementation {
  NSArray *fileUrls = self.fileUrls;

  DDLogDebug(@"VimR OSA: Calling open file in new windows command with args: %@", fileUrls);

  if (fileUrls.isEmpty) {
    DDLogDebug(@"VimR OSA: Opening an untitled window because there was no given file");
    [self.appDelegate.workspaceController newWorkspace];
    return nil;
  }

  for (NSURL *url in fileUrls) {
    [self.appDelegate application:self.app openFile:url.path];
  }

  return nil;
}

@end
