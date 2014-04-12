/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <MacVimFramework/MacVimFramework.h>


@class VRWorkspaceController;

@interface VRAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) NSApplication *application;
@property (weak) VRWorkspaceController *workspaceController;
@property (weak) NSWorkspace *workspace;

@property (assign) IBOutlet NSWindow *window;

#pragma mark IBActions
- (IBAction)newDocument:(id)sender;
- (IBAction)newTab:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)showHelp:(id)sender;

#pragma mark NSObject
- (id)init;

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication;
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames;
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;

@end
