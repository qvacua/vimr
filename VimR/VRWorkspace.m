/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import <TBCacao/TBCacao.h>
#import "VRWorkspace.h"
#import "VRMainWindowController.h"
#import "VROpenQuicklyWindowController.h"


@implementation VRWorkspace

#pragma mark Public
- (void)setUpWithVimController:(MMVimController *)vimController {
  VRMainWindowController *controller = [
      [VRMainWindowController alloc] initWithContentRect:CGRectMake(242, 364, 480, 360)
  ];
  controller.vimController = vimController;
  controller.vimView = vimController.vimView;
  // TODO: ugly
  controller.openQuicklyWindowController = [[TBContext sharedContext]
      beanWithClass:[VROpenQuicklyWindowController class]];

  vimController.delegate = (id <MMVimControllerDelegate>) controller;

  self.mainWindowController = controller;

  [controller showWindow:self];
}

- (void)cleanUpAndClose {
  [self.mainWindowController cleanUpAndClose];
}

@end
