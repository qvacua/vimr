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


static NSOpenPanel *openPanel;

@interface VRAppDelegateTest : VRBaseTestCase

@end

@implementation VRAppDelegateTest {
    VRAppDelegate *appDelegate;

    NSApplication *application;
    VRWorkspaceController *workspaceController;
    NSWorkspace *workspace;

    IMP openPanelOriginalImpl;
}

+ (NSOpenPanel *)mockOpenPanel {
    return openPanel;
}

- (void)setUp {
    [super setUp];

    application = mock([NSApplication class]);
    workspaceController = mock([VRWorkspaceController class]);
    workspace = mock([NSWorkspace class]);

    appDelegate = [[VRAppDelegate alloc] init];
    appDelegate.application = application;
    appDelegate.workspaceController = workspaceController;
    appDelegate.workspace = workspace;

    openPanel = mock([NSOpenPanel class]);
    openPanelOriginalImpl = [self mockClassSelector:@selector(openPanel) ofClass:[NSOpenPanel class]
                                       withSelector:@selector(mockOpenPanel) ofClass:[self class]];
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
    [verify(workspaceController) openFiles:@[
            [NSURL fileURLWithPath:@"/tmp"],
            [NSURL fileURLWithPath:@"/usr"]
    ]];
}

- (void)testOpenDocumentCancelled {
    [given([openPanel runModal]) willReturnInteger:NSCancelButton];

    [appDelegate openDocument:nil];
    [verify(openPanel) setAllowsMultipleSelection:YES];
    [verifyCount(workspaceController, never()) openFiles:anything()];
}

- (void)testApplicationOpenUntitledFile {
    assertThat(@([appDelegate applicationOpenUntitledFile:application]), isYes);
    [verify(workspaceController) newWorkspace];
}

- (void)testAppliationOpenFile {
    [appDelegate application:nil openFile:@"/tmp"];
    [verify(workspaceController) openFiles:@[
            [NSURL fileURLWithPath:@"/tmp"],
    ]];
}

- (void)testAppliationOpenFiles {
    NSArray *filenames = @[@"/tmp", @"/usr"];
    [appDelegate application:nil openFiles:filenames];
    [verify(workspaceController) openFiles:@[
            [NSURL fileURLWithPath:@"/tmp"],
            [NSURL fileURLWithPath:@"/usr"]
    ]];
}

- (void)testApplicationWillFinishLaunching {
    NSApplication *anApp = mock([NSApplication class]);
    NSNotification *notification = [[NSNotification alloc] initWithName:@"some-name" object:anApp userInfo:nil];

    [appDelegate applicationWillFinishLaunching:notification];
    assertThat(appDelegate.application, is(anApp));
}

- (void)testApplicationWillTerminate {
    [appDelegate applicationWillTerminate:nil];
    [verify(workspaceController) cleanup];
}

@end
