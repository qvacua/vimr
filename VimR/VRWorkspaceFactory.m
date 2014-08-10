/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRWorkspaceFactory.h"
#import "VRWorkspaceController.h"
#import "VRFileItemManager.h"
#import "VRWorkspace.h"
#import "VROpenQuicklyWindowController.h"
#import "VRMainWindowControllerFactory.h"


@implementation VRWorkspaceFactory

@autowire(fileManager)
@autowire(workspaceController)
@autowire(fileItemManager)
@autowire(userDefaults)
@autowire(notificationCenter)
@autowire(openQuicklyWindowController)
@autowire(mainWindowControllerFactory)

- (VRWorkspace *)newWorkspaceWithWorkingDir:(NSURL *)workingDir {
  VRWorkspace *workspace = [[VRWorkspace alloc] init];

  workspace.openQuicklyWindowController = _openQuicklyWindowController;
  workspace.fileItemManager = _fileItemManager;
  workspace.userDefaults = _userDefaults;
  workspace.notificationCenter = _notificationCenter;
  workspace.workspaceController = _workspaceController;
  workspace.mainWindowControllerFactory = _mainWindowControllerFactory;
  workspace.fileManager = _fileManager;

  workspace.workingDirectory = workingDir;

  return workspace;
}

@end
