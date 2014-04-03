/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import "VRWorkspaceController.h"
#import "VRMainWindowController.h"


NSString *const qMainWindowNibName = @"MainWindow";
NSString *const qVimArgFileNamesToOpen = @"filenames";
NSString *const qVimArgOpenFilesLayout = @"layout";


@implementation VRWorkspaceController

#pragma mark Public
- (void)newWorkspace {
    // TODO: for time being, only one main window
    if (self.mainWindowController == nil) {
        [self.vimManager pidOfNewVimControllerWithArgs:nil];
    }
}

- (void)openFiles:(NSArray *)fileUrls {
    // for time being, only one window
    NSDictionary *args = [self vimArgsFromFileUrls:fileUrls];

    if (self.mainWindowController) {
        [self.mainWindowController openFilesWithArgs:args];
    } else {
        [self.vimManager pidOfNewVimControllerWithArgs:args];
    }
}

- (void)cleanup {
    [self.vimManager terminateAllVimProcesses];
}

#pragma mark MMVimManagerDelegateProtocol
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller {
    _mainWindowController = [[VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName];
    _mainWindowController.vimController = controller;
    _mainWindowController.vimView = controller.vimView;

    controller.delegate = (id <MMVimControllerDelegate>) _mainWindowController;

    [_mainWindowController showWindow:self];
}

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)controllerId pid:(int)pid {
    [self.mainWindowController cleanupAndClose];
    self.mainWindowController = nil;
}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

#pragma mark Private
- (NSDictionary *)vimArgsFromFileUrls:(NSArray *)fileUrls {
    NSMutableArray *filenames = [[NSMutableArray alloc] initWithCapacity:4];
    for (NSURL *url in fileUrls) {
        [filenames addObject:url.path];
    }

    return @{
            qVimArgFileNamesToOpen : filenames,
            qVimArgOpenFilesLayout : @(MMLayoutTabs),
    };
}

@end
