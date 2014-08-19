/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRWorkspace.h"
#import "VRMainWindowController.h"
#import "VRMainWindowControllerFactory.h"
#import "VRFileItemManager.h"


@interface VRWorkspaceTest : VRBaseTestCase
@end

@implementation VRWorkspaceTest {
  VRWorkspace *workspace;

  MMVimController *vimController;
  NSWindow *window;
  VRMainWindowController *mainWindowController;
  VRMainWindowControllerFactory *mainWindowControllerFactory;
  VRFileItemManager *fileItemManager;

  NSURL *initialUrl;
}

- (void)setUp {
  [super setUp];

  workspace = [[VRWorkspace alloc] init];

  vimController = mock([MMVimController class]);

  window = mock([NSWindow class]);
  mainWindowController = mock([VRMainWindowController class]);
  mainWindowControllerFactory = mock([VRMainWindowControllerFactory class]);
  [[given([mainWindowControllerFactory newMainWindowControllerWithContentRect:CGRectZero
                                                                    workspace:workspace
                                                                vimController:vimController])
      withMatcher:anything() forArgument:0]
      willReturn:mainWindowController];

  [given([mainWindowController vimController]) willReturn:vimController];
  [given([mainWindowController window]) willReturn:window];

  fileItemManager = mock([VRFileItemManager class]);
  initialUrl = [NSURL URLWithString:@"file:///initial/url"];

  workspace.mainWindowControllerFactory = mainWindowControllerFactory;
  workspace.fileItemManager = fileItemManager;
  workspace.workingDirectory = initialUrl;

  [workspace setUpWithVimController:vimController];
}

- (void)testSelectUrl {
  NSURL *url = [NSURL URLWithString:@"file:///some/file"];
  [workspace selectBufferWithUrl:url];

  [verify(vimController) gotoBufferWithUrl:url];
  [verify(window) makeKeyAndOrderFront:anything()];
}

- (void)testUpdateWorkingDir {
  NSURL *newUrl = [NSURL URLWithString:@"file:///some/file"];
  [workspace updateWorkingDirectory:newUrl];

  [verify(fileItemManager) unregisterUrl:initialUrl];
  [verify(fileItemManager) registerUrl:newUrl];

  (workspace.workingDirectory, is(newUrl));
  [verify(mainWindowController) updateWorkingDirectory];
}

- (void)testOpenFilesWithUrls {
  NSArray *urls = @[@"1", @"2"];
  [workspace openFilesWithUrls:urls];
  [verify(mainWindowController) openFilesWithUrls:urls];
}

- (void)testHasModifiedBuffer {
  [given([vimController hasModifiedBuffer]) willReturnBool:YES];
  (@(workspace.hasModifiedBuffer), isYes);

  [given([vimController hasModifiedBuffer]) willReturnBool:NO];
  (@(workspace.hasModifiedBuffer), isNo);
}

- (void)testSetUpWithVimController {
  [verify(fileItemManager) registerUrl:initialUrl];
  [[verify(mainWindowControllerFactory) withMatcher:anything() forArgument:0] newMainWindowControllerWithContentRect:CGRectZero workspace:workspace vimController:vimController];
  [verify(vimController) setDelegate:mainWindowController];
}

- (void)testSetUpInitialBuffers {
  [given([vimController buffers]) willReturn:@[
      [[MMBuffer alloc] initWithNumber:0 fileName:@"/tmp/1" modified:NO],
      [[MMBuffer alloc] initWithNumber:1 fileName:@"/tmp/2" modified:NO]]
  ];
  [workspace setUpInitialBuffers];
  assertThat(workspace.openedUrls, consistsOfInAnyOrder(
      [NSURL fileURLWithPath:@"/tmp/1"],
      [NSURL fileURLWithPath:@"/tmp/2"])
  );
}

- (void)testUpdateBuffersNoop {
  [given([vimController buffers]) willReturn:@[
      [[MMBuffer alloc] initWithNumber:0 fileName:@"/tmp/1" modified:NO],
      [[MMBuffer alloc] initWithNumber:1 fileName:@"/tmp/2" modified:NO]]
  ];
  [workspace setUpInitialBuffers];
  workspace.workingDirectory = [NSURL fileURLWithPath:@"/tmp"];

  MMVimWindow *win1 = [[MMVimWindow alloc] initWithBuffer:[[MMBuffer alloc] initWithNumber:0 fileName:@"/tmp/1" modified:NO]];
  MMVimWindow *win2 = [[MMVimWindow alloc] initWithBuffer:[[MMBuffer alloc] initWithNumber:1 fileName:@"/tmp/2" modified:NO]];
  win1.currentWindow = YES;
  win2.currentWindow = YES;

  [given([vimController tabs]) willReturn:@[
      [[MMTabPage alloc] initWithVimWindows:@[win1]],
      [[MMTabPage alloc] initWithVimWindows:@[win2]],
  ]];
  [workspace updateBuffersInTabs];

  [verifyCount(fileItemManager, never()) unregisterUrl:anything()];
  [verifyCount(fileItemManager, times(1)) registerUrl:anything()]; // setUpWithVimController in setUp calls this, thus 1
  [verifyCount(mainWindowController, never()) updateWorkingDirectory];
}

- (void)testUpdateBuffersWithUntitledBuffer {
  NSURL *workingDir = [NSURL fileURLWithPath:@"/other"];
  workspace.workingDirectory = workingDir;
  [workspace updateBuffersInTabs];
  [verify(fileItemManager) unregisterUrl:workingDir];
  [verify(fileItemManager) registerUrl:[NSURL fileURLWithPath:NSHomeDirectory()]];
  [verify(mainWindowController) updateWorkingDirectory];
}

- (void)testUpdateBuffers {
  NSURL *workingDir = [NSURL fileURLWithPath:@"/tmp/folder"];

  [given([vimController buffers]) willReturn:@[
      [[MMBuffer alloc] initWithNumber:0 fileName:@"/tmp/folder/1" modified:NO],
      [[MMBuffer alloc] initWithNumber:1 fileName:@"/tmp/folder/2" modified:NO],
  ]];
  [workspace setUpInitialBuffers];
  workspace.workingDirectory = workingDir;

  MMVimWindow *win1 = [[MMVimWindow alloc] initWithBuffer:[[MMBuffer alloc] initWithNumber:0 fileName:@"/tmp/folder/1" modified:NO]];
  MMVimWindow *win2 = [[MMVimWindow alloc] initWithBuffer:[[MMBuffer alloc] initWithNumber:1 fileName:@"/tmp/folder/2" modified:NO]];
  MMVimWindow *win3 = [[MMVimWindow alloc] initWithBuffer:[[MMBuffer alloc] initWithNumber:2 fileName:@"/tmp/3" modified:NO]];
  win1.currentWindow = YES;
  win2.currentWindow = YES;
  win3.currentWindow = YES;

  [given([vimController tabs]) willReturn:@[
      [[MMTabPage alloc] initWithVimWindows:@[win1]],
      [[MMTabPage alloc] initWithVimWindows:@[win2]],
      [[MMTabPage alloc] initWithVimWindows:@[win3]],
  ]];
  [workspace updateBuffersInTabs];

  [verify(fileItemManager) unregisterUrl:workingDir];
  [verify(fileItemManager) registerUrl:[NSURL fileURLWithPath:@"/tmp"]];
  [verify(mainWindowController) updateWorkingDirectory];
}

- (void)testCleanUpAndClose {
  [workspace cleanUpAndClose];

  [verify(mainWindowController) cleanUpAndClose];
}

@end
