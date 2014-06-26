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


@implementation VRMainWindowControllerFactory

@autowire(userDefaults)

- (VRMainWindowController *)newMainWindowControllerWithContentRect:(CGRect)contentRect
                                                         workspace:(VRWorkspace *)workspace
                                                     vimController:(MMVimController *)vimController {

  VRMainWindowController *mainWinController = [[VRMainWindowController alloc] initWithContentRect:contentRect];
  mainWinController.workspace = workspace;

  mainWinController.vimController = vimController;
  mainWinController.vimView = vimController.vimView;

  vimController.delegate = (id <MMVimControllerDelegate>) mainWinController;

  return mainWinController;
}

@end
