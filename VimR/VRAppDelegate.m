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


@implementation VRAppDelegate {
  VRMainWindowController *_mainWindowController;
}

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

- (IBAction)debug3Action:(id)sender {
  [self application:_application openFiles:@[
      [NSURL fileURLWithPath:@"/Users/hat/Projects/vimr/Podfile"]
  ]];
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

  if ([fileNames[0] isKindOfClass:[NSURL class]]) {
    [self.workspaceController openFilesInNewWorkspace:fileNames];
    return;
  }

  [self.workspaceController openFilesInNewWorkspace:urls_from_paths(fileNames)];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  // this cannot be done with TBCacao
  _application = aNotification.object;

#ifdef DEBUG
  _debug.hidden = NO;
#endif
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

@end
