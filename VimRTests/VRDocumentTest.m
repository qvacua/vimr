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
}

- (void)setUp {
    [super setUp];

    document = [[VRDocument alloc] init];
}

- (void)testMakeWindowControllers {
    [document makeWindowControllers];
    assertThat(document.mainWindowController, instanceOf([VRMainWindowController class]));
    assertThat(document.mainWindowController.windowNibName, is(qMainWindowNibName));
}

@end
