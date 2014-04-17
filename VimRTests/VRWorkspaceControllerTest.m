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

    VRMainWindowController *mainWindowController;
    MMVimManager *vimManager;
}

- (void)setUp {
    [super setUp];

    vimManager = mock([MMVimManager class]);
    mainWindowController = mock([VRMainWindowController class]);

    workspaceController = [[VRWorkspaceController alloc] init];
    workspaceController.vimManager = vimManager;
}

- (void)testNewWorkspace {
    [workspaceController newWorkspace];
    [verify(vimManager) pidOfNewVimControllerWithArgs:nil];
    [self emulateControllerCreated];

    // TODO: for time being, only one main window!
    [workspaceController newWorkspace];
    [verifyCount(vimManager, times(1)) pidOfNewVimControllerWithArgs:anything()];
}

- (void)testOpenFilesWitoutMainWindow {
    NSArray *urls = @[[NSURL URLWithString:@"file:///some/file"], [NSURL URLWithString:@"file:///another/file"]];

    [workspaceController openFiles:urls];
    [verify(vimManager) pidOfNewVimControllerWithArgs:@{
            qVimArgFileNamesToOpen : @[@"/some/file", @"/another/file"],
            qVimArgOpenFilesLayout : @(MMLayoutTabs)
    }];
}

- (void)testOpenFilesWithMainWindow {
    NSArray *urls = @[[NSURL URLWithString:@"file:///some/file"], [NSURL URLWithString:@"file:///another/file"]];

    [workspaceController newWorkspace];
    [self emulateControllerCreated];

    [workspaceController openFiles:urls];
    [verify(mainWindowController) openFilesWithArgs:@{
            qVimArgFileNamesToOpen : @[@"/some/file", @"/another/file"],
            qVimArgOpenFilesLayout : @(MMLayoutTabs)
    }];
}

- (void)testCleanup {
    [workspaceController cleanUp];
    [verify(vimManager) terminateAllVimProcesses];
}

- (void)testManagerVimControllerCreated {
}

- (void)testManagerVimControllerRemovedWithControllerIdPid {
    [self emulateControllerCreated];

    [workspaceController manager:vimManager vimControllerRemovedWithControllerId:123 pid:987];
    [verify(mainWindowController) cleanUpAndClose];
}

- (void)testMenuItemTemplateForManager {
    assertThat([workspaceController menuItemTemplateForManager:vimManager], isNot(nilValue()));
}

- (void)emulateControllerCreated {
    // not very elegant, but emulate that the vim manager created the vim controller
//    workspaceController.mainWindowController = mainWindowController;
}

@end
