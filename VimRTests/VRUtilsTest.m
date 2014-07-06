/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRUtils.h"


@interface VRUtilsTest : VRBaseTestCase
@end


@implementation VRUtilsTest {
  NSString *rsrcPath;
}

- (void)setUp {
  rsrcPath = [[NSBundle bundleForClass:[self class]] resourcePath];
}

- (void)testCommonParentUrl {
  NSURL *url1 = [NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1/level-1-file-1"]];
  NSURL *url2 = [NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1/level-2-a"]];
  NSURL *url3 = [NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1/level-2-b/level-2-b-file-1"]];

  NSURL *parent = common_parent_url(@[url1, url2, url3]);
  assertThat(parent, is([NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1"]]));
}

- (void)testCommonParentUrlWithOneDir {
  NSURL *parent = common_parent_url(@[[NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1"]]]);
  assertThat(parent, is([NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1"]]));
}

- (void)testUrlsFromPaths {
  NSArray *paths = @[
      @"/System/Library",
      @"/Library",
  ];

  assertThat(urls_from_paths(paths), consistsOfInAnyOrder(
      [NSURL fileURLWithPath:@"/System/Library"],
      [NSURL fileURLWithPath:@"/Library"]
  ));
}

@end
