/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import "VRWorkspace.h"
#import "VRMainWindowController.h"


@implementation VRWorkspace

#pragma mark Public
- (BOOL)hasModifiedBuffer {
  return self.mainWindowController.vimController.hasModifiedBuffer;
}

- (void)setUpWithVimController:(MMVimController *)vimController {
    VRMainWindowController *controller = [[VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName];
    controller.vimController = vimController;
    controller.vimView = vimController.vimView;

    vimController.delegate = (id <MMVimControllerDelegate>) controller;

    self.mainWindowController = controller;

    [controller showWindow:self];
}

- (void)cleanUpAndClose {
    [self.mainWindowController cleanUpAndClose];
}

@end
