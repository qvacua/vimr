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


@implementation VRMainWindowControllerFactory

@autowire(pluginManager)
@autowire(notificationCenter)

- (VRMainWindowController *)newMainWindowControllerWithContentRect:(CGRect)contentRect workspace:(VRWorkspace *)workspace vimController:(MMVimController *)vimController {
  VRMainWindowController *mainWinController = [[VRMainWindowController alloc] initWithContentRect:contentRect];
  mainWinController.workspace = workspace;
  mainWinController.vimController = vimController;
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
