/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <MacVimFramework/MacVimFramework.h>
#import "VRMainWindowControllerFactory.h"
#import "VRWorkspace.h"
#import "VRMainWindowController.h"
#import "VRPluginManager.h"
#import "VRPreviewWindowController.h"
#import "VRFileItemManager.h"
#import "VROpenQuicklyWindowController.h"
#import "VRWorkspaceViewFactory.h"
#import "VRFileBrowserViewFactory.h"


@implementation VRMainWindowControllerFactory

@autowire(userDefaults)
@autowire(fileItemManager)
@autowire(openQuicklyWindowController)
@autowire(pluginManager)
@autowire(notificationCenter)
@autowire(workspaceViewFactory)
@autowire(fileBrowserViewFactory)
@autowire(fontManager)

- (VRMainWindowController *)newMainWindowControllerWithContentRect:(CGRect)contentRect
                                                          workspace:(VRWorkspace *)workspace
                                                      vimController:(MMVimController *)vimController {

  VRMainWindowController *mainWinController = [[VRMainWindowController alloc] initWithContentRect:contentRect];
  mainWinController.workspace = workspace;
  mainWinController.vimController = vimController;
  mainWinController.fileItemManager = _fileItemManager;
  mainWinController.openQuicklyWindowController = _openQuicklyWindowController;
  mainWinController.userDefaults = _userDefaults;
  mainWinController.workspaceViewFactory = _workspaceViewFactory;
  mainWinController.fileBrowserViewFactory = _fileBrowserViewFactory;
  mainWinController.fontManager = _fontManager;

  mainWinController.vimView = vimController.vimView;

  vimController.delegate = (id <MMVimControllerDelegate>) mainWinController;

  VRPreviewWindowController *previewWindowController = [[VRPreviewWindowController alloc] initWithMainWindowController:mainWinController];
  previewWindowController.pluginManager = _pluginManager;
  previewWindowController.notificationCenter = _notificationCenter;
  [previewWindowController setUp];

  mainWinController.previewWindowController = previewWindowController;

  return mainWinController;
}

@end
