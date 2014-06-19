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
#import "VRMainWindowController.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRWorkspace.h"
#import "VROpenQuicklyWindowController.h"
#import "VRDefaultLogSetting.h"
#import "VRMainWindow.h"
#import "NSArray+VR.h"
#import "VRPrefWindow.h"


static NSString *const qVimRHelpUrl = @"http://vimdoc.sourceforge.net/htmldoc/";


@implementation VRAppDelegate

@manualwire(userDefaults)
@manualwire(workspace)
@manualwire(workspaceController)
@manualwire(fileItemManager)
@manualwire(openQuicklyWindowController)
@manualwire(prefWindow)

#pragma mark IBActions
- (IBAction)newDocument:(id)sender {
  [self applicationOpenUntitledFile:_application];
}

- (IBAction)newTab:(id)sender {
  [self newDocument:sender];
}

- (IBAction)openDocument:(id)sender {
  NSArray *urls = [self urlsFromOpenPanel];

  if (!urls || urls.isEmpty) {
    return;
  }

  DDLogDebug(@"opening %@", urls);
  [self application:_application openFiles:urls];
}

- (IBAction)openDocumentInTab:(id)sender {
  NSWindow *keyWindow = _application.keyWindow;
  if (![keyWindow isKindOfClass:[VRMainWindow class]]) {
    return;
  }

  NSArray *urls = [self urlsFromOpenPanel];
  VRMainWindowController *controller = (VRMainWindowController *) keyWindow.windowController;
  [controller.workspace openFilesWithUrls:urls];
}

- (IBAction)showHelp:(id)sender {
  [self.workspace openURL:[[NSURL alloc] initWithString:qVimRHelpUrl]];
}

- (IBAction)showPrefWindow:(id)sender {
  if ([_userDefaults objectForKey:SF(@"NSWindow Frame %@", qPrefWindowFrameAutosaveName])) {
    [_prefWindow setFrameUsingName:qPrefWindowFrameAutosaveName];
  } else {
    [_prefWindow center];
  }

  [_prefWindow makeKeyAndOrderFront:self];
}

- (IBAction)toggleShowFoldersFirst:(id)sender {
  // noop
}

- (IBAction)toggleShowHiddenFiles:(id)sender {
  // noop
}

- (IBAction)toggleSyncWorkspaceWithPwd:(id)sender {
  // noop
}

#ifdef DEBUG
- (IBAction)debug3Action:(id)sender {
  [self application:_application openFiles:@[
      [NSURL fileURLWithPath:@"/Users/hat/Projects/vimr/Podfile"]
  ]];
}
#endif

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  SEL action = anItem.action;

  if (action == @selector(newDocument:)) {return YES;}
  if (action == @selector(newTab:)) {return YES;}
  if (action == @selector(openDocument:)) {return YES;}
  if (action == @selector(openDocumentInTab:)) {return YES;}
  if (action == @selector(showHelp:)) {return YES;}
  if (action == @selector(showPrefWindow:)) {return YES;}

#ifdef DEBUG
  if (action == @selector(debug3Action:)) {return YES;}
#endif

  if (action == @selector(toggleShowFoldersFirst:)) {
    [(NSMenuItem *) anItem setState:[_userDefaults boolForKey:qDefaultShowFoldersFirst]];
    return NO;
  }

  if (action == @selector(toggleShowHiddenFiles:)) {
    [(NSMenuItem *) anItem setState:[_userDefaults boolForKey:qDefaultShowHiddenInFileBrowser]];
    return NO;
  }

  if (action == @selector(toggleSyncWorkspaceWithPwd:)) {
    [(NSMenuItem *) anItem setState:[_userDefaults boolForKey:qDefaultSyncWorkingDirectoryWithVimPwd]];
    return NO;
  }

  return NO;
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  [[TBContext sharedContext] autowireSeed:self];

  return self;
}

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
  [_workspaceController newWorkspace];
  return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [self application:sender openFiles:@[filename]];
  return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)fileNames {
  /**
  * fileNames consists of
  * - NSURLs when opening files via NSOpenPanel
  * - NSStrings when opening files via drag and drop on the VimR icon
  */

  NSMutableArray *urls;
  if ([fileNames[0] isKindOfClass:[NSURL class]]) {
    urls = [fileNames mutableCopy];
  } else {
    urls = [urls_from_paths(fileNames) mutableCopy];
  }

  NSArray *alreadyOpenedUrls = [self alreadyOpenedUrlsInUrls:urls];
  [urls removeObjectsInArray:alreadyOpenedUrls];

  if (urls.isEmpty) {
    [self postUserNotificationWithTitle:@"All selected file(s) are already opened."];
    [_workspaceController selectBufferWithUrl:alreadyOpenedUrls[0]];

    return;
  }

  if (!alreadyOpenedUrls.isEmpty) {
    [self postUserNotificationWithTitle:@"There are already opened files."];
  }

  [_workspaceController openFilesInNewWorkspace:urls];
}

- (NSArray *)alreadyOpenedUrlsInUrls:(NSArray *)urls {
  NSMutableSet *openedUrls = [[NSMutableSet alloc] init];
  for (VRWorkspace *workspace in _workspaceController.workspaces) {
    [openedUrls addObjectsFromArray:workspace.openedUrls];
  }

  NSMutableSet *result = [[NSMutableSet alloc] initWithArray:urls];
  [result intersectSet:openedUrls];

  return result.allObjects;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  // this cannot be done with TBCacao
  _application = aNotification.object;

  _userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
  _userNotificationCenter.delegate = self;

  [self setInitialUserDefaults];

#ifdef DEBUG
  _debug.hidden = NO;
#endif
}

- (void)setInitialUserDefaults {
  if (![_userDefaults objectForKey:qDefaultShowStatusBar]) {
    [_userDefaults setBool:YES forKey:qDefaultShowStatusBar];
  }

  if (![_userDefaults objectForKey:qDefaultShowFoldersFirst]) {
    [_userDefaults setBool:YES forKey:qDefaultShowFoldersFirst];
  }

  if (![_userDefaults objectForKey:qDefaultShowHiddenInFileBrowser]) {
    [_userDefaults setBool:NO forKey:qDefaultShowHiddenInFileBrowser];
  }

  if (![_userDefaults objectForKey:qDefaultSyncWorkingDirectoryWithVimPwd]) {
    [_userDefaults setBool:YES forKey:qDefaultSyncWorkingDirectoryWithVimPwd];
  }

  if (![_userDefaults objectForKey:qDefaultDefaultOpeningBehavior]) {
    [_userDefaults setObject:qOpenModeInNewTabValue forKey:qDefaultDefaultOpeningBehavior];
  }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  if (![_workspaceController hasDirtyBuffers]) {
    return NSTerminateNow;
  }

  NSAlert *alert = [self warnBeforeQuitAlert];
  if (alert.runModal != NSAlertFirstButtonReturn) {
    return NSTerminateCancel;
  }

  return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [_workspaceController cleanUp];
  [_fileItemManager cleanUp];
  [_openQuicklyWindowController cleanUp];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return YES;
}

#pragma mark NSUserNotificationCenterDelegate
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {

  return YES;
}

#pragma mark Private

- (NSArray *)urlsFromOpenPanel {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  openPanel.allowsMultipleSelection = YES;

  if ([openPanel runModal] != NSOKButton) {
    DDLogDebug(@"no files selected");
    return nil;
  }

  return openPanel.URLs;
}

- (NSAlert *)warnBeforeQuitAlert {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.alertStyle = NSWarningAlertStyle;
  [alert addButtonWithTitle:@"Quit"];
  [alert addButtonWithTitle:@"Cancel"];
  alert.messageText = @"Quit without saving?";
  alert.informativeText = @"There are modified buffers, if you quit now all changes will be lost. Quit anyway?";

  return alert;
}

- (void)postUserNotificationWithTitle:(NSString *)title {
  NSUserNotification *userNotification = [[NSUserNotification alloc] init];
  userNotification.title = title;
  [_userNotificationCenter scheduleNotification:userNotification];
}

@end
