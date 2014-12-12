/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenFileInFrontmostWindowCommand.h"
#import "VRDefaultLogSetting.h"
#import "VRAppDelegate.h"
#import "VRMainWindow.h"
#import "VRWorkspace.h"


@implementation VROpenFileInFrontmostWindowCommand {

}

#pragma mark NSScriptCommand
- (id)performDefaultImplementation {
  NSArray *fileUrls = self.fileUrls;
  VRMainWindow *mainWindow = self.evaluatedArguments[@"window"];
  if (mainWindow == nil) {
    DDLogWarn(@"VimR OSA: There is no main window. Doing nothing.");
    return nil;
  }

  VRWorkspace *workspace = [mainWindow.windowController workspace];;
  [workspace openFilesWithUrls:fileUrls];

  return nil;
}

@end
