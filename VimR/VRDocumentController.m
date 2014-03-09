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
#import "VRLog.h"
#import "VRUtils.h"


NSString *const qMainWindowNibName = @"MainWindow";
NSString *const qVimArgFileNamesToOpen = @"filenames";

@interface VRDocumentController ()

@property NSMutableDictionary *vimController2MainWindowController;

@end


@implementation VRDocumentController

#pragma mark IBActions
- (IBAction)newTab:(id)sender {
    log4Mark;
    [self openUntitledDocumentAndDisplay:YES error:NULL];
}

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:
        (void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {

    void (^handler)(NSDocument *, BOOL, NSError *) = ^(NSDocument *document, BOOL alreadyOpen, NSError *error) {
        [[self mainWindowControllerForDocument:(VRDocument *) document] showWindow:self];
    };

    [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:handler];
}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    log4Mark;

    VRDocument *newDoc = [self makeUntitledDocumentOfType:self.defaultType error:outError];
    [self addDocument:newDoc];

    VRMainWindowController *mainWindowController = [self mainWindowControllerForDocument:newDoc];
    [mainWindowController showWindow:self];

    return newDoc;
}

#pragma mark NSDocumentController
- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _vimController2MainWindowController = [[NSMutableDictionary alloc] initWithCapacity:4];

    return self;
}

- (void)dealloc {
    [self.vimManager terminateAllVimProcesses];
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

    for (VRDocument *doc in windowControllerToClose.documents) {
        [doc close];
    }
    [windowControllerToClose.documents removeAllObjects];
    [windowControllerToClose close];

    [self.vimController2MainWindowController removeObjectForKey:@(pid)];
}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

#pragma mark Private
- (VRMainWindowController *)mainWindowControllerForDocument:(VRDocument *)doc {
    // TODO: for time being, only use one window...

    if (self.vimController2MainWindowController.count > 0) {
        VRMainWindowController *mainWindowController = self.vimController2MainWindowController.allValues[0];
        VRDocument *currentlyVisibleDocument = mainWindowController.selectedDocument;

        /**
         * We could use
         * [mainWindowController.vimController sendMessage:OpenWithArgumentsMsgID
         *                                     data:[@{qVimArgFileNamesToOpen: @[doc.fileURL.path]} dictionaryAsData]];
         * which checks whether the currently visible document is transient and act appropriately.
         * We want to keep the opened files and our list of VRDocuments in sync, thus, we do it manually here
         */
        if (currentlyVisibleDocument.transient) {
            NSString *command = SF(@":e %@", doc.fileURL.path.stringByEscapingSpecialFilenameCharacters);
            [mainWindowController sendCommandToVim:command];
            [mainWindowController removeDocument:currentlyVisibleDocument];
        } else {
            NSString *command = SF(@":tabe %@", doc.fileURL.path.stringByEscapingSpecialFilenameCharacters);
            [mainWindowController sendCommandToVim:command];
        }

        doc.mainWindowController = mainWindowController;
        [mainWindowController.documents addObject:doc];

        return mainWindowController;
    }

    VRMainWindowController *mainWindowController = [
            [VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName
    ];
    mainWindowController.documentController = self;

    NSDictionary *args = nil;
    NSURL *url = doc.fileURL;

    if (url != nil) {
        args = @{qVimArgFileNamesToOpen : @[url.path]};
    }
    int pid = [self.vimManager pidOfNewVimControllerWithArgs:args];

    self.vimController2MainWindowController[@(pid)] = mainWindowController;

    [mainWindowController.documents addObject:doc];
    doc.mainWindowController = mainWindowController;

    return mainWindowController;
}

@end
