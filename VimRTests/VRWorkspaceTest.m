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


@interface VRWorkspaceTest : VRBaseTestCase
@end

@implementation VRWorkspaceTest {
  VRWorkspace *workspace;

  MMVimController *vimController;
  NSWindow *window;
  VRMainWindowController *mainWindowController;
  VRMainWindowControllerFactory *mainWindowControllerFactory;
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

  workspace.mainWindowControllerFactory = mainWindowControllerFactory;

  [workspace setUpWithVimController:vimController];
}

- (void)testSelectUrl {
  NSURL *url = [NSURL URLWithString:@"file:///some/file"];
  [workspace selectBufferWithUrl:url];

  [verify(vimController) gotoBufferWithUrl:url];
  [verify(window) makeKeyAndOrderFront:anything()];
}

- (void)testHasModifiedBuffer {
  [given([vimController hasModifiedBuffer]) willReturnBool:YES];
  (@(workspace.hasModifiedBuffer), isYes);

  [given([vimController hasModifiedBuffer]) willReturnBool:NO];
  (@(workspace.hasModifiedBuffer), isNo);
}

- (void)notTestSetUpWithVimController {
  // cannot load Nib
}

- (void)testCleanUpAndClose {
  [workspace cleanUpAndClose];

  [verify(mainWindowController) cleanUpAndClose];
}

@end
