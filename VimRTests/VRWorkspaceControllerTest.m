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
#import "VRWorkspace.h"


@interface VRWorkspaceControllerTest : VRBaseTestCase

@end

@implementation VRWorkspaceControllerTest {
  VRWorkspaceController *workspaceController;

  MMVimManager *vimManager;
  MMVimController *vimController;
}

- (void)setUp {
  [super setUp];

  vimManager = mock([MMVimManager class]);
  vimController = mock([MMVimController class]);

  workspaceController = [[VRWorkspaceController alloc] init];
  workspaceController.vimManager = vimManager;
}

- (void)testNewWorkspace {
  [given([vimManager pidOfNewVimControllerWithArgs:nil]) willReturnInt:123];
  [workspaceController newWorkspace];
  [verify(vimManager) pidOfNewVimControllerWithArgs:nil];
}

- (void)testOpenFiles {
  NSArray *urls = @[
      [NSURL URLWithString:@"file:///some/folder/is/1.txt"],
      [NSURL URLWithString:@"file:///some/folder/2.txt"],
      [NSURL URLWithString:@"file:///some/folder/is/there/3.txt"],
      [NSURL URLWithString:@"file:///some/folder/is/not/there/4.txt"],
  ];
  [given([vimManager pidOfNewVimControllerWithArgs:nil]) willReturnInt:123];

  [workspaceController openFiles:urls];
  [verify(vimManager) pidOfNewVimControllerWithArgs:@{
      qVimArgFileNamesToOpen : @[
          @"/some/folder/is/1.txt",
          @"/some/folder/2.txt",
          @"/some/folder/is/there/3.txt",
          @"/some/folder/is/not/there/4.txt",
      ],
      qVimArgOpenFilesLayout : @(MMLayoutTabs)
  }];
}

- (void)testCleanup {
  [workspaceController cleanUp];
  [verify(vimManager) terminateAllVimProcesses];
}

- (void)testManagerVimControllerCreated {
  NSArray *urls = @[
      [NSURL URLWithString:@"file:///some/folder/is/1.txt"],
      [NSURL URLWithString:@"file:///some/folder/2.txt"],
      [NSURL URLWithString:@"file:///some/folder/is/there/3.txt"],
      [NSURL URLWithString:@"file:///some/folder/is/not/there/4.txt"],
  ];
  [given([vimManager pidOfNewVimControllerWithArgs:nil]) willReturnInt:123];
  [workspaceController openFiles:urls];

  [workspaceController manager:vimManager vimControllerCreated:vimController];

  VRWorkspace *workspace = workspaceController.workspaces[0];
  assertThat(workspace.workingDirectory, is([NSURL fileURLWithPath:@"/some/folder"]));
  // cannot verify [workspace setUpWithVimController:vimController]
}

- (void)testManagerVimControllerRemovedWithControllerIdPid {
  [given([vimManager pidOfNewVimControllerWithArgs:nil]) willReturnInt:123];
  [workspaceController newWorkspace];

  [workspaceController manager:vimManager vimControllerRemovedWithControllerId:456 pid:123];
  assertThat(workspaceController.workspaces, isEmpty());
}

- (void)testMenuItemTemplateForManager {
  assertThat([workspaceController menuItemTemplateForManager:vimManager], isNot(nilValue()));
}

@end
