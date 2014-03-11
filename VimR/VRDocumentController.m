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
#import "NSArray+VR.h"


NSString *const qMainWindowNibName = @"MainWindow";
NSString *const qVimArgFileNamesToOpen = @"filenames";
NSString *const qVimArgOpenFilesLayout = @"layout";

@interface VRDocumentController ()

@property NSMutableDictionary *vimController2MainWindowController;

@end


@implementation VRDocumentController

#pragma mark IBActions
- (IBAction)newTab:(id)sender {
    [self openUntitledDocumentAndDisplay:YES error:NULL];
}

- (IBAction)openDocument:(id)sender {
    // TODO: filter out already opened documents
    NSArray *fileUrls = [self URLsFromRunningOpenPanel];
    if ([fileUrls isEmpty]) {
        return;
    }

    NSArray *docs = [self documentsFromUrls:fileUrls];
    for (VRDocument *doc in docs) {
        [self addDocument:doc];
    }

    [self openDocuments:docs];

}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    VRDocument *doc = [self makeUntitledDocumentOfType:self.defaultType error:outError];
    [self addDocument:doc];

    [self openDocuments:@[doc]];

    return doc;
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
- (VRMainWindowController *)existingMainWindowController {
    // TODO: for time being, use only one window...
    return self.vimController2MainWindowController.allValues[0];
}

- (VRMainWindowController *)newMainWindowControllerForDocuments:(NSArray *)docs {
    VRMainWindowController *mainWindowController = [
            [VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName
    ];
    mainWindowController.documentController = self;

    NSDictionary *args = nil;
    if (![self isOpeningNewDoc:docs]) {
        NSMutableArray *filenames = [[NSMutableArray alloc] initWithCapacity:docs.count];
        for (VRDocument *doc in docs) {
            [filenames addObject:doc.fileURL.path];
        }
        args = @{
                qVimArgFileNamesToOpen : filenames,
                qVimArgOpenFilesLayout : @(MMLayoutTabs),
        };
    }

    int pid = [self.vimManager pidOfNewVimControllerWithArgs:args];
    self.vimController2MainWindowController[@(pid)] = mainWindowController;

    return mainWindowController;
}

- (BOOL)isOpeningNewDoc:(NSArray *)docs {
    return [docs[0] isNewDocument] && docs.count == 1;
}

- (NSArray *)documentsFromUrls:(NSArray *)fileUrls {
    NSMutableArray *docs = [[NSMutableArray alloc] initWithCapacity:4];
    for (NSURL *url in fileUrls) {
        NSString *type = [self typeForContentsOfURL:url error:NULL];
        VRDocument *doc = [[VRDocument alloc] initWithContentsOfURL:url ofType:type error:NULL];

        [docs addObject:doc];
    }

    return docs;
}

- (void)openDocuments:(NSArray *)docs {
    VRMainWindowController *mainWindowController;
    if (self.vimController2MainWindowController.count > 0) {
        // open docs in the existing window in tabs
        mainWindowController = [self existingMainWindowController];
        [mainWindowController openDocuments:docs];
    } else {
        // no existing window, create one
        mainWindowController = [self newMainWindowControllerForDocuments:docs];
    }

    for (VRDocument *doc in docs) {
        [mainWindowController insertObject:doc inDocumentsAtIndex:mainWindowController.countOfDocuments];
    }

    [mainWindowController showWindow:self];
}

@end
