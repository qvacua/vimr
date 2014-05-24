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


@implementation VRUtilsTest

- (void)testCommonParentUrl {
  NSURL *parent = common_parent_url(@[
      [NSURL fileURLWithPath:@"/a/b/c/d/e.txt"],
      [NSURL fileURLWithPath:@"/a/b/c/d/1/2/3/o.txt"],
      [NSURL fileURLWithPath:@"/a/b/c/ae.txt"],
      [NSURL fileURLWithPath:@"/a/b/c/d/3.txt"],
  ]);

  assertThat(parent.path, is(@"/a/b/c"));
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
