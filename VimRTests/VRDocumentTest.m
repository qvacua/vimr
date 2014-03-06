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
#import "VRDocument.h"


@interface VRDocumentTest : VRBaseTestCase

@end

@implementation VRDocumentTest {
    VRDocument *document;

    VRMainWindowController *mainWindowController;
}

- (void)setUp {
    [super setUp];

    mainWindowController = mock([VRMainWindowController class]);

    document = [[VRDocument alloc] init];
    document.mainWindowController = mainWindowController;
}

- (void)testMakeWindowControllers {
    [document makeWindowControllers];
    assertThat(document.mainWindowController, instanceOf([VRMainWindowController class]));
    assertThat(document.mainWindowController.windowNibName, is(qMainWindowNibName));
}

@end
