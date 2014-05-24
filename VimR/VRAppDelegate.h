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
@class VRFileItemManager;
@class VROpenQuicklyWindowController;

@interface VRAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) NSApplication *application;
@property (nonatomic, weak) VRWorkspaceController *workspaceController;
@property (nonatomic, weak) NSWorkspace *workspace;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) VROpenQuicklyWindowController *openQuicklyWindowController;

@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSMenuItem *debug;

#pragma mark IBActions
- (IBAction)newDocument:(id)sender;
- (IBAction)newTab:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)openDocumentInTab:(id)sender;
- (IBAction)showHelp:(id)sender;

#pragma mark NSObject
- (id)init;

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication;
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
- (void)application:(NSApplication *)sender openFiles:(NSArray *)fileNames;
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;

@end
