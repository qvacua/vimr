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


@interface VRWorkspaceTest : VRBaseTestCase
@end

@implementation VRWorkspaceTest {
  VRWorkspace *workspace;

  MMVimController *vimController;
  VRMainWindowController *mainWindowController;
}

- (void)setUp {
  [super setUp];

  vimController = mock([MMVimController class]);
  mainWindowController = mock([VRMainWindowController class]);

  [given([mainWindowController vimController]) willReturn:vimController];

  workspace = [[VRWorkspace alloc] init];
  workspace.mainWindowController = mainWindowController;
}

- (void)testHasModifiedBuffer {
  [given([vimController hasModifiedBuffer]) willReturnBool:YES];
  assertThat(@(workspace.hasModifiedBuffer), isYes);

  [given([vimController hasModifiedBuffer]) willReturnBool:NO];
  assertThat(@(workspace.hasModifiedBuffer), isNo);
}

- (void)notTestSetUpWithVimController {
  // cannot load Nib
}

- (void)testCleanUpAndClose {
  [workspace cleanUpAndClose];

  [verify(mainWindowController) cleanUpAndClose];
}

@end
