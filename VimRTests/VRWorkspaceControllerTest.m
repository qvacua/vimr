/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRMainWindowController.h"
#import "VRWorkspaceController.h"


@interface VRWorkspaceControllerTest : VRBaseTestCase

@end

@implementation VRWorkspaceControllerTest {
    VRWorkspaceController *workspaceController;
    MMVimManager *vimManager;
}

- (void)setUp {
    [super setUp];

    vimManager = mock([MMVimManager class]);

    workspaceController = [[VRWorkspaceController alloc] init];
    workspaceController.vimManager = vimManager;
}

- (void)testNewWorkspace {
    [workspaceController newWorkspace];
    [verify(vimManager) pidOfNewVimControllerWithArgs:nil];
    // not very elegant, but emulate that the vim manager created the vim controller
    [workspaceController manager:nil vimControllerCreated:nil];

    // TODO: for time being, only one main window!
    [workspaceController newWorkspace];
    [verifyCount(vimManager, times(1)) pidOfNewVimControllerWithArgs:anything()];
}

@end
