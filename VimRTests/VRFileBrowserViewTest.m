/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRFileItemManager.h"
#import "VRFileBrowserView.h"
#import "VRUserDefaults.h"
#import "VRWorkspaceView.h"
#import "VRFileBrowserOutlineView.h"


@interface VRFileBrowserViewTest : VRBaseTestCase
@end

@implementation VRFileBrowserViewTest {
  NSURL *level1;
  VRFileItemManager *fileItemManager;
  NSUserDefaults *userDefaults;
  VRWorkspaceView *workspaceView;

  VRFileBrowserView *fileBrowserView;
}

#define LEVEL1(name) [level1.path stringByAppendingPathComponent:name]
#define LEVEL2A(name) [level2aPath stringByAppendingPathComponent:name]
#define LEVEL2B(name) [level2bPath stringByAppendingPathComponent:name]

- (void)setUp {
  [super setUp];

  NSURL *rsrcUrl = [NSBundle bundleForClass:self.class].resourceURL;
  level1 = [rsrcUrl URLByAppendingPathComponent:@"level-1" isDirectory:YES];

  fileItemManager = [[VRFileItemManager alloc] init];
  fileItemManager.fileManager = [NSFileManager defaultManager];
  fileItemManager.notificationCenter = [NSNotificationCenter defaultCenter];

  [fileItemManager registerUrl:level1];

  userDefaults = mock([NSUserDefaults class]);
  [given([userDefaults boolForKey:qDefaultShowHiddenInFileBrowser]) willReturnBool:NO];

  workspaceView = mock([VRWorkspaceView class]);
  
  NSString *level2aPath = LEVEL1(@"level-2-a");
  NSString *level2bPath = LEVEL1(@"level-2-b");
  
  [given([workspaceView nonFilteredWildIgnorePathsForParentPath:level1.path]) willReturn:@[
                                                                                          LEVEL1(@"level-1-file-1"),
                                                                                          LEVEL1(@"level-1-file-2"),
                                                                                          LEVEL1(@"level-1-file-3"),
                                                                                          LEVEL1(@"level-1-file-4"),
                                                                                          LEVEL1(@"level-2-a"),
                                                                                          LEVEL1(@"level-2-b"),
                                                                                          ]];
  [given([workspaceView nonFilteredWildIgnorePathsForParentPath:level2aPath]) willReturn:@[
                                                                                           LEVEL2A(@"level-2-a-file-1"),
                                                                                           LEVEL2A(@"level-2-a-file-2"),
                                                                                           LEVEL2A(@"level-2-a-file-3"),
                                                                                           LEVEL2A(@"level-2-a-file-4"),
                                                                                           LEVEL2A(@"level-2-a-file-5"),
                                                                                           ]];
  [given([workspaceView nonFilteredWildIgnorePathsForParentPath:level2bPath]) willReturn:@[
                                                                                           LEVEL2B(@"level-2-b-file-1"),
                                                                                           LEVEL2B(@"level-2-b-file-2"),
                                                                                           LEVEL2B(@".level-2-b-file-3"),
                                                                                           ]];
  fileBrowserView = [[VRFileBrowserView alloc] initWithRootUrl:level1];
  fileBrowserView.userDefaults = userDefaults;
  fileBrowserView.fileItemManager = fileItemManager;
  fileBrowserView.rootUrl = level1;
  fileBrowserView.workspaceView = workspaceView;

  [fileBrowserView setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testOutlineViewDataSourceMethods {
  assertThat(@([fileBrowserView outlineView:nil numberOfChildrenOfItem:nil]), is(@6));

  for (NSUInteger i = 0; i < 6; i++) {
    id child = [fileBrowserView outlineView:nil child:i ofItem:nil];

    if ([[fileBrowserView outlineView:nil objectValueForTableColumn:nil byItem:child] isEqualToString:@"level-2-a"]) {
      [self assertLevel2a:child];
    }

    if ([[child name] isEqualToString:@"level-2-b"]) {
      [self assertLevel2b:child];
    }
  }
}

- (void)testOutlineViewDataSourceMethodsWithHiddenItems {
  [given([workspaceView showHiddenFiles]) willReturnBool:YES];

  for (NSUInteger i = 0; i < 6; i++) {
    id child = [fileBrowserView outlineView:nil child:i ofItem:nil];

    if ([[fileBrowserView outlineView:nil objectValueForTableColumn:nil byItem:child] isEqualToString:@"level-2-b"]) {
      assertThat(@([fileBrowserView outlineView:nil numberOfChildrenOfItem:child]), is(@3));

      for (NSUInteger j = 0; j < 3; j++) {
        if ([[fileBrowserView outlineView:nil objectValueForTableColumn:nil byItem:child]
            isEqualToString:@".level-2-b-file-3"]) {
          assertThat(@([fileBrowserView outlineView:nil isItemExpandable:child]), isNo);
          assertThat(@([child isHidden]), isYes);
        }
      }
    }
  }
}

- (void)testOutlineViewDataSourceMethodsWithWildIgnoreItems {
  [given([workspaceView nonFilteredWildIgnorePathsForParentPath:level1.path]) willReturn:@[
                                                                                          LEVEL1(@"level-1-file-1"),
                                                                                          LEVEL1(@"level-1-file-2"),
                                                                                          ]];
  [fileBrowserView reload];
  assertThat(@([fileBrowserView outlineView:nil numberOfChildrenOfItem:nil]), is(@2));
}

- (void)assertLevel2a:(id)node {
  assertThat(@([fileBrowserView outlineView:nil numberOfChildrenOfItem:node]), is(@5));
  assertThat(@([node isDir]), isYes);
  assertThat(@([node isHidden]), isNo);

  for (NSUInteger i = 0; i < 5; i++) {
    id child = [fileBrowserView outlineView:nil child:i ofItem:node];
    assertThat([fileBrowserView outlineView:nil objectValueForTableColumn:nil byItem:child],
        containsString(@"level-2-a-file-"));
    assertThat(@([fileBrowserView outlineView:nil isItemExpandable:child]), isNo);
    assertThat(@([child isHidden]), isNo);
  }
}

- (void)assertLevel2b:(id)node {
  assertThat(@([fileBrowserView outlineView:nil numberOfChildrenOfItem:node]), is(@2));
  assertThat(@([node isDir]), isYes);
  assertThat(@([node isHidden]), isNo);

  for (NSUInteger i = 0; i < 2; i++) {
    id child = [fileBrowserView outlineView:nil child:i ofItem:node];
    assertThat([fileBrowserView outlineView:nil objectValueForTableColumn:nil byItem:child],
        containsString(@"level-2-b-file-"));
    assertThat(@([child isDir]), isNo);
    assertThat(@([child isHidden]), isNo);
  }
}

@end
