/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRMainWindowController.h"
#import "VRWorkspaceController.h"
#import "VRAppDelegate.h"
#import "VRWorkspace.h"


static NSOpenPanel *openPanel;

@interface VRAppDelegateTest : VRBaseTestCase

@end

@implementation VRAppDelegateTest {
  VRAppDelegate *appDelegate;

  NSUserDefaults *userDefaults;
  NSUserNotificationCenter *userNotificationCenter;
  NSApplication *application;
  VRWorkspaceController *workspaceController;
  NSWorkspace *workspace;

  IMP openPanelOriginalImpl;
  VRWorkspace *workspace1;
  VRWorkspace *workspace2;
}

+ (NSOpenPanel *)mockOpenPanel {
  return openPanel;
}

- (void)setUp {
  [super setUp];

  userDefaults = mock([NSUserDefaults class]);
  application = mock([NSApplication class]);
  workspaceController = mock([VRWorkspaceController class]);
  workspace = mock([NSWorkspace class]);
  userNotificationCenter = mock([NSUserNotificationCenter class]);

  appDelegate = [[VRAppDelegate alloc] init];
  appDelegate.userNotificationCenter = userNotificationCenter;
  appDelegate.application = application;
  appDelegate.workspaceController = workspaceController;
  appDelegate.workspace = workspace;
  appDelegate.userDefaults = userDefaults;

  openPanel = mock([NSOpenPanel class]);
  openPanelOriginalImpl = [self mockClassSelector:@selector(openPanel) ofClass:[NSOpenPanel class]
                                     withSelector:@selector(mockOpenPanel) ofClass:[self class]];

  workspace1 = mock([VRWorkspace class]);
  workspace2 = mock([VRWorkspace class]);

  [given([workspace1 openedUrls]) willReturn:@[
      [NSURL fileURLWithPath:@"/some/path/to/file1"],
      [NSURL fileURLWithPath:@"/some/path/to/file2"],
  ]];

  [given([workspace2 openedUrls]) willReturn:@[
      [NSURL fileURLWithPath:@"/some/other/path/to/file1"],
      [NSURL fileURLWithPath:@"/some/other/path/to/file2"],
  ]];
}

- (void)tearDown {
  [super tearDown];

  [self restoreClassSelector:@selector(openPanel) ofClass:[NSOpenPanel class] withImpl:openPanelOriginalImpl];
}

- (void)testInit {
  [verify(self.context) autowireSeed:appDelegate];
}

- (void)testNewDocument {
  [appDelegate newDocument:nil];
  [verify(workspaceController) newWorkspace];
}

- (void)testNewDocumentOpenUntitledOnLaunch {
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnLaunch]) willReturnBool:YES];
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnReactivation]) willReturnBool:NO];

  [appDelegate applicationWillFinishLaunching:nil];
  [appDelegate applicationOpenUntitledFile:application];

  [verify(workspaceController) newWorkspace];
}

- (void)testNewDocumentDoNotOpenUntitledOnLaunch {
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnLaunch]) willReturnBool:NO];
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnReactivation]) willReturnBool:YES];

  [appDelegate applicationWillFinishLaunching:nil];
  [appDelegate applicationOpenUntitledFile:application];

  [verifyCount(workspaceController, times(0)) newWorkspace];
}

- (void)testNewDocumentDoNotOpenUntitledOnReactivation {
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnLaunch]) willReturnBool:YES];
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnReactivation]) willReturnBool:NO];

  [appDelegate applicationWillFinishLaunching:nil];
  [appDelegate applicationOpenUntitledFile:application];
  [appDelegate applicationDidFinishLaunching:nil];

  [appDelegate applicationOpenUntitledFile:application];

  [verifyCount(workspaceController, times(1)) newWorkspace];
}

- (void)testNewDocumentOpenUntitledOnReactivation {
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnLaunch]) willReturnBool:YES];
  [given([userDefaults boolForKey:qDefaultOpenUntitledWindowModeOnReactivation]) willReturnBool:YES];

  [appDelegate applicationWillFinishLaunching:nil];
  [appDelegate applicationOpenUntitledFile:application];
  [appDelegate applicationDidFinishLaunching:nil];

  [appDelegate applicationOpenUntitledFile:application];

  [verifyCount(workspaceController, times(2)) newWorkspace];
}

- (void)testNewTab {
  [appDelegate newTab:nil];
  [verify(workspaceController) newWorkspace];
}

- (void)testOpenDocument {
  NSArray *filenames = @[@"/tmp", @"/usr"];
  [given([openPanel runModal]) willReturnInteger:NSOKButton];
  [given([openPanel URLs]) willReturn:filenames];

  [appDelegate openDocument:nil];
  [verify(openPanel) setAllowsMultipleSelection:YES];
  [verify(openPanel) setCanChooseDirectories:YES];
  [verify(workspaceController) openFilesInNewWorkspace:@[
      [NSURL fileURLWithPath:@"/tmp"],
      [NSURL fileURLWithPath:@"/usr"]
  ]];
}

- (void)testOpenDocumentCancelled {
  [given([openPanel runModal]) willReturnInteger:NSCancelButton];

  [appDelegate openDocument:nil];
  [verify(openPanel) setAllowsMultipleSelection:YES];
  [verify(openPanel) setCanChooseDirectories:YES];
  [verifyCount(workspaceController, never()) openFilesInNewWorkspace:anything()];
}

- (void)testAppliationOpenFile {
  [given([workspaceController workspaces]) willReturn:@[]];

  [appDelegate application:nil openFile:@"/tmp"];
  [verify(workspaceController) openFilesInNewWorkspace:@[
      [NSURL fileURLWithPath:@"/tmp"],
  ]];
}

- (void)testAppliationOpenFilesWithNoOpenUrls {
  [given([workspaceController workspaces]) willReturn:@[]];

  NSArray *filenames = @[@"/tmp", @"/usr"];
  [appDelegate application:nil openFiles:filenames];
  [verify(workspaceController) openFilesInNewWorkspace:@[
      [NSURL fileURLWithPath:@"/tmp"],
      [NSURL fileURLWithPath:@"/usr"]
  ]];
}

- (void)testApplicationOpenFilesWithAllOpenUrls {
  [given([workspaceController workspaces]) willReturn:@[workspace1, workspace2]];

  [appDelegate application:nil openFiles:@[
      [NSURL fileURLWithPath:@"/some/path/to/file2"],
      [NSURL fileURLWithPath:@"/some/other/path/to/file1"],
  ]];

  [verify(userNotificationCenter) scheduleNotification:instanceOf([NSUserNotification class])];
  [verify(workspaceController) selectBufferWithUrl:[NSURL fileURLWithPath:@"/some/path/to/file2"]];
}

- (void)testApplicationOpenFilesWithPartiallyOpenUrls {
  [given([workspaceController workspaces]) willReturn:@[workspace1, workspace2]];

  [appDelegate application:nil openFiles:@[
      [NSURL fileURLWithPath:@"/some/path/to/file2"],
      [NSURL fileURLWithPath:@"/some/other/path/to/file3"],
  ]];

  [verify(userNotificationCenter) scheduleNotification:instanceOf([NSUserNotification class])];
  [verify(workspaceController) openFilesInNewWorkspace:@[
      [NSURL fileURLWithPath:@"/some/other/path/to/file3"],
  ]];
}

- (void)testApplicationWillFinishLaunching {
  NSApplication *anApp = mock([NSApplication class]);
  NSNotification *notification = [[NSNotification alloc] initWithName:@"some-name" object:anApp userInfo:nil];

  [appDelegate applicationWillFinishLaunching:notification];
  assertThat(appDelegate.application, is(anApp));
}

- (void)notTestApplicationShouldTerminate {
  // We use [[NSAlert alloc] init]...
}

- (void)testApplicationWillTerminate {
  [appDelegate applicationWillTerminate:nil];
  [verify(workspaceController) cleanUp];
}

@end
