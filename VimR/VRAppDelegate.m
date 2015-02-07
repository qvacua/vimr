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
#import "NSArray+VR.h"
#import "VRAppDelegate.h"
#import "VRWorkspaceController.h"
#import "VRMainWindowController.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRWorkspace.h"
#import "VROpenQuicklyWindowController.h"
#import "VRDefaultLogSetting.h"
#import "VRMainWindow.h"
#import "VRApplication.h"
#import "VRPrefWindow.h"
#import "VRPropertyService.h"
#import "VRKeyBinding.h"
#import "VRMenuItem.h"


static NSString *const qVimRHelpUrl = @"https://github.com/qvacua/vimr/wiki";


@implementation VRAppDelegate {
  BOOL _isLaunching;
}

@manualwire(userDefaults)
@manualwire(workspace)
@manualwire(workspaceController)
@manualwire(fileItemManager)
@manualwire(openQuicklyWindowController)
@manualwire(prefWindow)
@manualwire(propertyReader)

#pragma mark IBActions
- (IBAction)newDocument:(id)sender {
  [_workspaceController newWorkspace];
}

- (IBAction)newTab:(id)sender {
  [self newDocument:sender];
}

- (IBAction)openDocument:(id)sender {
  NSArray *urls = [self urlsFromOpenPanelWithCanChooseDir:YES];

  if (!urls || urls.isEmpty) {
    return;
  }

  [self application:_application openFiles:urls];
}

- (IBAction)openDocumentInTab:(id)sender {
  NSWindow *keyWindow = _application.keyWindow;
  if (![keyWindow isKindOfClass:[VRMainWindow class]]) {
    return;
  }

  NSArray *urls = [self urlsFromOpenPanelWithCanChooseDir:NO];
  VRWorkspace *workspace = [(VRMainWindowController *) keyWindow.windowController workspace];
  [workspace openFilesWithUrls:urls];
}

- (IBAction)showHelp:(id)sender {
  [self.workspace openURL:[NSURL URLWithString:qVimRHelpUrl]];
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

- (IBAction)toggleSidebarOnRight:(id)sender {
  // noop
}

- (IBAction)toggleStatusBar:(id)sender {
  // noop
}

#ifdef DEBUG
- (IBAction)debug3Action:(id)sender {
  [self application:_application openFiles:@[[NSURL fileURLWithPath:@"/Users/hat/Projects/vimr-pages/index.html"]]];
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
    [(NSMenuItem *) anItem setState:[_userDefaults boolForKey:qDefaultFileBrowserShowFoldersFirst]];
    return NO;
  }

  if (action == @selector(toggleShowHiddenFiles:)) {
    [(NSMenuItem *) anItem setState:[_userDefaults boolForKey:qDefaultFileBrowserShowHidden]];
    return NO;
  }

  if (action == @selector(toggleSyncWorkspaceWithPwd:)) {
    [(NSMenuItem *) anItem setState:[_userDefaults boolForKey:qDefaultFileBrowserSyncWorkingDirWithVimPwd]];
    return NO;
  }

  if (action == @selector(toggleSidebarOnRight:)) {
    if ([_userDefaults boolForKey:qDefaultShowSideBarOnRight]) {
      [(NSMenuItem *) anItem setTitle:@"Put Sidebar on Left"];
    } else {
      [(NSMenuItem *) anItem setTitle:@"Put Sidebar on Right"];
    }

    return NO;
  }

  if (action == @selector(toggleStatusBar:)) {
    if ([_userDefaults boolForKey:qDefaultShowStatusBar]) {
      [(NSMenuItem *) anItem setTitle:@"Hide Status Bar"];
    } else {
      [(NSMenuItem *) anItem setTitle:@"Show Status Bar"];
    }

    return NO;
  }

  return NO;
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  [[TBContext sharedContext] initContext];
  [[TBContext sharedContext] autowireSeed:self];

  return self;
}

#pragma mark NSApplicationDelegate
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
  if (_isLaunching) {
    if ([_userDefaults boolForKey:qDefaultOpenUntitledWinModeOnLaunch]) {
      [_workspaceController newWorkspace];
    }
  } else {
    if ([_userDefaults boolForKey:qDefaultOpenUntitledWinModeOnReactivation]) {
      [_workspaceController newWorkspace];
    }
  }

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

  NSArray *alreadyOpenUrls = [self alreadyOpenedUrlsInUrls:urls];
  [urls removeObjectsInArray:alreadyOpenUrls];

  if (urls.isEmpty) {
    [self postUserNotificationWithTitle:@"All selected file(s) are already open."];
    [_workspaceController ensureUrlsAreVisible:alreadyOpenUrls];

    return;
  }

  if (!alreadyOpenUrls.isEmpty) {
    [self postUserNotificationWithTitle:@"There are already opened files."];
    [_workspaceController ensureUrlsAreVisible:alreadyOpenUrls];
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
  _isLaunching = YES;

  // this cannot be done with TBCacao
  _application = aNotification.object;

  _userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
  _userNotificationCenter.delegate = self;

  [self setInitialUserDefaults];

#ifdef DEBUG
  _debug.hidden = NO;
#endif

  [self updateKeyBindingsOfMenuItems];
  [self addTabKeyShortcuts];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  _isLaunching = NO;
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
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
  return YES;
}

#pragma mark Private
- (NSArray *)urlsFromOpenPanelWithCanChooseDir:(BOOL)canChooseDir {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  openPanel.allowsMultipleSelection = YES;
  openPanel.canChooseDirectories = canChooseDir;

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

- (void)setInitialUserDefaults {
  if (![_userDefaults objectForKey:qDefaultShowStatusBar]) {
    [_userDefaults setBool:YES forKey:qDefaultShowStatusBar];
  }

  if (![_userDefaults objectForKey:qDefaultFileBrowserShowFoldersFirst]) {
    [_userDefaults setBool:YES forKey:qDefaultFileBrowserShowFoldersFirst];
  }

  if (![_userDefaults objectForKey:qDefaultFileBrowserShowHidden]) {
    [_userDefaults setBool:NO forKey:qDefaultFileBrowserShowHidden];
  }

  if (![_userDefaults objectForKey:qDefaultFileBrowserSyncWorkingDirWithVimPwd]) {
    [_userDefaults setBool:YES forKey:qDefaultFileBrowserSyncWorkingDirWithVimPwd];
  }

  if (![_userDefaults objectForKey:qDefaultFileBrowserOpeningBehavior]) {
    [_userDefaults setObject:qOpenModeInNewTabValue forKey:qDefaultFileBrowserOpeningBehavior];
  }

  if (![_userDefaults objectForKey:qDefaultShowSideBar]) {
    [_userDefaults setBool:YES forKey:qDefaultShowSideBar];
  }

  if (![_userDefaults objectForKey:qDefaultShowSideBarOnRight]) {
    [_userDefaults setBool:NO forKey:qDefaultShowSideBarOnRight];
  }

  if (![_userDefaults objectForKey:qDefaultAutoSaveOnFrameDeactivation]) {
    [_userDefaults setBool:NO forKey:qDefaultAutoSaveOnFrameDeactivation];
  }

  if (![_userDefaults objectForKey:qDefaultAutoSaveOnCursorHold]) {
    [_userDefaults setBool:NO forKey:qDefaultAutoSaveOnCursorHold];
  }

  if (![_userDefaults objectForKey:qDefaultFileBrowserHideWildignore]) {
    [_userDefaults setBool:YES forKey:qDefaultFileBrowserHideWildignore];
  }

  if (![_userDefaults objectForKey:qDefaultOpenUntitledWinModeOnLaunch]) {
    [_userDefaults setBool:YES forKey:qDefaultOpenUntitledWinModeOnLaunch];
  }

  if (![_userDefaults objectForKey:qDefaultOpenUntitledWinModeOnReactivation]) {
    [_userDefaults setBool:YES forKey:qDefaultOpenUntitledWinModeOnReactivation];
  }

  if (![_userDefaults objectForKey:qDefaultQuitWhenLastWindowCloses]) {
    [_userDefaults setBool:NO forKey:qDefaultQuitWhenLastWindowCloses];
  }
}

- (void)addTabKeyShortcuts {
  if (!_propertyReader.useSelectNthTabBindings) {
    return;
  }

  NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:9];
  for (NSUInteger i = 0; i < 9; i++) {
    VRKeyBinding *item = [[VRKeyBinding alloc] initWithAction:@selector(selectNthTab:)
                                                    modifiers:_propertyReader.selectNthTabModifiers
                                                keyEquivalent:SF(@"%lu", i + 1)
                                                          tag:i];
    [items addObject:item];
  }

  [_application addKeyShortcutItems:items];
}

- (void)updateKeyBindingsOfMenuItems {
  for (NSString *keyBindingKey in _propertyReader.keysForKeyBindings) {
    NSString *menuItemIdentifier = [keyBindingKey substringFromIndex:27];

    VRMenuItem *menuItem = [self menuItemWithIdentifier:menuItemIdentifier];
    VRKeyBinding *keyBinding = [_propertyReader keyBindingForMenuItem:menuItem];

    // no custom key binding set
    if (keyBinding == nil) {
      continue;
    }

    menuItem.keyEquivalent = keyBinding.keyEquivalent;
    menuItem.keyEquivalentModifierMask = keyBinding.modifiers;
  }
}

- (VRMenuItem *)menuItemWithIdentifier:(NSString *)identifier {
  for (NSMenuItem *menu in [_application mainMenu].itemArray) {
    for (id menuItem in menu.submenu.itemArray) {
      if ([menuItem isKindOfClass:[VRMenuItem class]] && [[menuItem menuItemIdentifier] isEqualToString:identifier]) {
        return menuItem;
      }
    }
  }

  return nil;
}

@end
