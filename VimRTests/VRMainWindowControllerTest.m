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
#import "VRUtils.h"


/**
* No ARC, since we want to test also the -dealloc.
*
* TODO: tests for Vim controller delegate methods will be done when they get a bit more mature...
* TODO: OCMockito cannot handle CGRect yet, wanted to test -vimController:openWindowWithData:, but...
*/
@interface VRMainWindowControllerTest : VRBaseTestCase

@end

@implementation VRMainWindowControllerTest {
    VRMainWindowController *mainWindowController;

    NSWindow *window;
    NSView *contentView;
    MMVimController *vimController;
    MMVimView *vimView;
}

- (void)setUp {
    [super setUp];

    window = mock([NSWindow class]);
    contentView = mock([NSView class]);
    vimController = mock([MMVimController class]);
    vimView = mock([MMVimView class]);

    [given([window contentView]) willReturn:contentView];
    [given([vimController vimView]) willReturn:vimView];

    mainWindowController = [[VRMainWindowController alloc] init];
    mainWindowController.window = window;
    mainWindowController.vimController = vimController;
    mainWindowController.vimView = vimView;
}

- (void)testOpenFilesWithArgs {
    NSDictionary *args = @{@"some" : @"value"};

    [mainWindowController openFilesWithArgs:args];
    [verify(vimController) sendMessage:OpenWithArgumentsMsgID data:args.dictionaryAsData];
}

- (void)testCleanupAndClose {
    [mainWindowController cleanupAndClose];
    [verify(vimView) removeFromSuperviewWithoutNeedingDisplay];
    [verify(vimView) cleanup];
    // cannot verify [mainWindowController close]
}

- (void)testNewTab {
    [mainWindowController newTab:nil];
    [verify(vimController) addVimInput:[self vimInputWithString:@":tabe"]];
}

- (void)testPerformClose {
    [mainWindowController performClose:nil];
    [verify(vimController) sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:@[@"File", @"Close"]]];
}

- (void)testSaveDocument {
    [mainWindowController saveDocument:nil];
    [verify(vimController) sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:@[@"File", @"Save"]]];
}

- (void)testWindowDidBecomeMain {
    [mainWindowController windowDidBecomeMain:nil];
    [verify(vimController) sendMessage:GotFocusMsgID data:nil];
}

- (void)testWindowDidResignMain {
    [mainWindowController windowDidResignMain:nil];
    [verify(vimController) sendMessage:LostFocusMsgID data:nil];
}

- (void)testWindowShouldClose {
    BOOL shouldClose = [mainWindowController windowShouldClose:nil];

    assertThat(@(shouldClose), isNo);
    [verify(vimController) sendMessage:VimShouldCloseMsgID data:nil];
}

- (NSData *)dataFromDescriptor:(NSArray *)descriptor {
    return [@{@"descriptor" : descriptor} dictionaryAsData];
}

- (NSString *)vimInputWithString:(NSString *)cmd {
    return SF(@"<C-\\><C-N>%@<CR>", cmd);
}

@end
