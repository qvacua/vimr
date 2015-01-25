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
@class VRPrefWindow;
@class VRApplication;
@class VRPropertyReader;

@interface VRAppDelegate : NSObject <
    NSApplicationDelegate,
    NSUserNotificationCenterDelegate,
    NSUserInterfaceValidations>

@property (nonatomic, weak) VRApplication *application;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) VRWorkspaceController *workspaceController;
@property (nonatomic, weak) NSWorkspace *workspace;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) VROpenQuicklyWindowController *openQuicklyWindowController;
@property (nonatomic, weak) VRPrefWindow *prefWindow;
@property (nonatomic, weak) NSUserNotificationCenter *userNotificationCenter;
@property (nonatomic, weak) VRPropertyReader *propertyReader;

@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSMenuItem *debug;
@property (nonatomic, weak) IBOutlet NSMenuItem *tabs;

#pragma mark IBActions
- (IBAction)newDocument:(id)sender;
- (IBAction)newTab:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)openDocumentInTab:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showPrefWindow:(id)sender;

- (IBAction)toggleShowFoldersFirst:(id)sender;
- (IBAction)toggleShowHiddenFiles:(id)sender;
- (IBAction)toggleSyncWorkspaceWithPwd:(id)sender;
- (IBAction)toggleSidebarOnRight:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;

#pragma mark NSObject
- (id)init;

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication;
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
- (void)application:(NSApplication *)sender openFiles:(NSArray *)fileNames;
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;

#pragma mark NSUserNotificationCenterDelegate
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification;

@end
