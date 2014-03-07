/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import "VRDocumentController.h"
#import "VRDocument.h"
#import "VRMainWindowController.h"


NSString *const qVimArgFileNamesToOpen = @"filenames";

@interface VRDocumentController ()

@property NSMutableDictionary *vimController2Doc;
@property NSMutableDictionary *vimController2MainWindowController;

@end


@implementation VRDocumentController

#pragma mark Public
- (VRMainWindowController *)mainWindowControllerForDocument:(VRDocument *)doc {
    VRMainWindowController *mainWindowController = [
            [VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName
    ];

    NSDictionary *args = @{
            qVimArgFileNamesToOpen : @[doc.fileURL.path]
    };
    int pid = [self.vimManager pidOfNewVimControllerWithArgs:args];

    self.vimController2Doc[@(pid)] = doc;
    self.vimController2MainWindowController[@(pid)] = mainWindowController;

    [mainWindowController.documents addObject:doc];

    return mainWindowController;
}

#pragma mark NSDocumentController
- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _vimController2Doc = [[NSMutableDictionary alloc] initWithCapacity:4];
    _vimController2MainWindowController = [[NSMutableDictionary alloc] initWithCapacity:4];

    return self;
}

- (void)dealloc {
    [self.vimManager terminateAllVimProcesses];
}

- (void)addDocument:(NSDocument *)document {
    [super addDocument:document];

    VRDocument *vrDocument = (VRDocument *) document;
    vrDocument.documentController = self;
}

#pragma mark MMVimManagerDelegateProtocol
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller {
    VRMainWindowController *mainWindowController = self.vimController2MainWindowController[@(controller.pid)];

    controller.delegate = (id <MMVimControllerDelegate>) mainWindowController;

    mainWindowController.vimController = controller;
    mainWindowController.vimView = controller.vimView;
}

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)vimControllerId
            pid:(int)pid {

    VRMainWindowController *windowControllerToClose = self.vimController2MainWindowController[@(pid)];
    VRDocument *doc = self.vimController2Doc[@(pid)];

    [windowControllerToClose.documents removeObject:doc];
    [windowControllerToClose cleanup];

    [self.vimController2MainWindowController removeObjectForKey:@(pid)];
    [doc close]; // FIXME: ask when there are unsaved files, for time being, just close the document
}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

@end
