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


@interface VRDocumentController ()

@property NSMutableDictionary *vimController2Doc;

@end


@implementation VRDocumentController

#pragma mark Public
- (void)requestVimControllerForDocument:(VRDocument *)doc {
    int pid = [self.vimManager pidOfNewVimControllerWithArgs:nil];

    self.vimController2Doc[@(pid)] = doc;
}

#pragma mark NSDocumentController
- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _vimController2Doc = [[NSMutableDictionary alloc] initWithCapacity:4];

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
    VRDocument *doc = self.vimController2Doc[@(controller.pid)];
    VRMainWindowController *mainWindowController = doc.mainWindowController;

    controller.delegate = (id <MMVimControllerDelegate>) mainWindowController;

    mainWindowController.vimController = controller;
    mainWindowController.vimView = controller.vimView;
}

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)vimControllerId
            pid:(int)pid {

    VRDocument *doc = self.vimController2Doc[@(pid)];
    [doc close]; // FIXME: ask when there are unsaved files, for time being, just close the document
}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

@end
