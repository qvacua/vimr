/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRGoToLineOfFileCommand.h"
#import "VRDefaultLogSetting.h"
#import "VRAppDelegate.h"
#import "VRWorkspaceController.h"
#import "VRWorkspace.h"
#import "VRMainWindowController.h"
#import "VRUtils.h"


@implementation VRGoToLineOfFileCommand

#pragma mark NSScriptCommand
- (id)performDefaultImplementation {
  VRAppDelegate *appDelegate = [NSApp delegate];
  NSArray *workspaces = appDelegate.workspaceController.workspaces;

  NSUInteger line = [self.evaluatedArguments[@""] unsignedIntegerValue];
  NSURL *fileUrl = self.evaluatedArguments[@"file"];
  DDLogDebug(@"VimR OSA: Going to line %@ of file %@", @(line), fileUrl);

  for (VRWorkspace *workspace in workspaces) {
    for (MMBuffer *buffer in workspace.mainWindowController.vimController.buffers) {
      if ([[NSURL fileURLWithPath:buffer.fileName] isEqual:fileUrl]) {
        [self goToLine:line ofFile:fileUrl inWorkspace:workspace];
        return nil;
      }
    }
  }

  DDLogDebug(@"VimR OSA: The file %@ is not yet open; opening...");
  VRWorkspace *workspace;

  // synchronize such that nobody else creates a workspace in the time between the creation and waiting
  @synchronized (workspaces) {
    [appDelegate application:NSApp openFiles:@[fileUrl]];
    workspace = workspaces.lastObject;
  }

  // wait till Vim is up and running
  while (!workspace.mainWindowController.loadDone && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);

  [self goToLine:line ofFile:fileUrl inWorkspace:workspace];

  return nil;
}

#pragma mark Private
- (void)goToLine:(NSUInteger)line ofFile:(NSURL *)fileUrl inWorkspace:(VRWorkspace *)workspace {
  [workspace selectBufferWithUrl:fileUrl];
  [workspace.mainWindowController.vimController addVimInput:SF(@"<C-\\><C-N>:%lu<CR>", line)];
}

@end
