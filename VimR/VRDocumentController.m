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

    void (^handler)(NSDocument *, BOOL, NSError *) = ^(NSDocument *nsDoc, BOOL alreadyOpen, NSError *error) {
        VRDocument *doc = (VRDocument *) nsDoc;

        VRMainWindowController *controller = [self mainWindowControllerForDocument:doc];
        [controller insertObject:doc inDocumentsAtIndex:controller.countOfDocuments];
        [controller showWindow:self];
    };

    [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:handler];
}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    log4Mark;

    VRDocument *newDoc = [self makeUntitledDocumentOfType:self.defaultType error:outError];
    [self addDocument:newDoc];

    VRMainWindowController *mainWindowController = [self mainWindowControllerForDocument:newDoc];
    [mainWindowController insertObject:newDoc inDocumentsAtIndex:mainWindowController.countOfDocuments];
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

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)controllerId pid:(int)pid {
    [self.vimController2MainWindowController[@(pid)] cleanupAndClose];
    [self.vimController2MainWindowController removeObjectForKey:@(pid)];
}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

#pragma mark Private
- (VRMainWindowController *)mainWindowControllerForDocument:(VRDocument *)doc {
    // TODO: for time being, use only one window...

    if (self.vimController2MainWindowController.count > 0) {
        return self.vimController2MainWindowController.allValues[0];
    }

    return [self newMainWindowControllerForDocument:doc];
}

- (VRMainWindowController *)newMainWindowControllerForDocument:(VRDocument *)doc {
    VRMainWindowController *mainWindowController = [
            [VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName
    ];
    mainWindowController.documentController = self;

    NSURL *url = doc.fileURL;
    NSDictionary *args = nil;
    if (url != nil) {
        args = @{qVimArgFileNamesToOpen : @[url.path]};
    }

    int pid = [self.vimManager pidOfNewVimControllerWithArgs:args];
    self.vimController2MainWindowController[@(pid)] = mainWindowController;

    return mainWindowController;
}

@end
