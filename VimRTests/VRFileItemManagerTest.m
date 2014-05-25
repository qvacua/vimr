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


@interface VRFileItemManagerTest : VRBaseTestCase
@end

@implementation VRFileItemManagerTest {
  VRFileItemManager *fileItemManager;

  NSURL *level1;
}

- (void)setUp {
  [super setUp];

  fileItemManager = [[VRFileItemManager alloc] init];
  fileItemManager.fileManager = [NSFileManager defaultManager];
  fileItemManager.notificationCenter = [NSNotificationCenter defaultCenter];

  NSURL *rsrcUrl = [[NSBundle bundleForClass:self.class] resourceURL];
  level1 = [rsrcUrl URLByAppendingPathComponent:@"level-1" isDirectory:YES];
}

- (void)tearDown {
  [super tearDown];

  [fileItemManager cleanUp];
}

- (void)testRegisterUrl {
  [fileItemManager registerUrl:level1];
  assertThat(fileItemManager.registeredUrls, hasItem(level1));
}

- (void)testBuildFileItemsHierarchy {
  [fileItemManager registerUrl:level1];
  [fileItemManager setTargetUrl:level1];

  // we wait some time till the background thread has finished its job: 2s should be enough...
  sleep(2);

  NSArray *resultItems = fileItemManager.urlsOfTargetUrl;
  assertThat(resultItems, hasCountOf(12));
  assertThat([NSSet setWithArray:resultItems], hasCountOf(12)); // we just check whether all items are unique...
}

- (void)testTwiceSetTargetUrl {
  [fileItemManager registerUrl:level1];
  [fileItemManager setTargetUrl:level1];

  // we wait some time till the background thread has finished its job: 2s should be enough...
  sleep(2);

  [fileItemManager resetTargetUrl];
  [fileItemManager setTargetUrl:level1];
  // we wait some time till the background thread has finished its job: 2s should be enough...
  sleep(2);

  NSArray *resultItems = fileItemManager.urlsOfTargetUrl;
  assertThat(resultItems, hasCountOf(12));
  assertThat([NSSet setWithArray:resultItems], hasCountOf(12)); // we just check whether all items are unique...
}

- (void)testMultipleTargetUrls {
  NSURL *level2a = [level1 URLByAppendingPathComponent:@"level-2-a"];
  NSURL *level2b = [level1 URLByAppendingPathComponent:@"level-2-b"];

  [fileItemManager registerUrl:level2a];
  [fileItemManager registerUrl:level2b];

  [fileItemManager setTargetUrl:level2b];
  sleep(1);
  assertThat(fileItemManager.urlsOfTargetUrl, hasCountOf(3));

  [fileItemManager setTargetUrl:level2a];
  sleep(1);
  assertThat(fileItemManager.urlsOfTargetUrl, hasCountOf(5));
}

- (void)testUnregisterUrl {
  [fileItemManager registerUrl:level1];

  [fileItemManager unregisterUrl:level1];
  assertThat(fileItemManager.registeredUrls, isNot(hasItem(level1)));
}

@end
