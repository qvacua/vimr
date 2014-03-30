/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <MacVimFramework/MacVimFramework.h>
#import "VRAppDelegate.h"
#import "VRWorkspaceController.h"
#import "VRLog.h"
#import "VRMainWindowController.h"


static NSString *const qVimRHelpUrl = @"http://vimdoc.sourceforge.net/htmldoc/";

@interface VRAppDelegate ()

@property VRMainWindowController *mainWindowController;

@end

@implementation VRAppDelegate

TB_MANUALWIRE(workspace)
TB_MANUALWIRE(workspaceController)

#pragma mark IBActions
- (IBAction)newDocument:(id)sender {
    [self applicationOpenUntitledFile:self.application];
}

- (IBAction)newTab:(id)sender {
    // when we're here, no window is open yet
    [self newDocument:sender];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = YES;

    if ([openPanel runModal] != NSOKButton) {
        log4Debug(@"no files selected");
        return;
    }

    log4Debug(@"opening %@", openPanel.URLs);
    [self application:self.application openFiles:openPanel.URLs];
}

- (IBAction)showHelp:(id)sender {
    [self.workspace openURL:[[NSURL alloc] initWithString:qVimRHelpUrl]];
}

#pragma mark NSObject
- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    [[TBContext sharedContext] autowireSeed:self];

    return self;
}

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
    [self.workspaceController newWorkspace];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)fileUrls {
    [self.workspaceController openFiles:fileUrls];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // cannot be done with TBCacao
    self.application = aNotification.object;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return YES;
}

@end
