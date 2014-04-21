/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "NSURL+VR.h"


@interface NSURLCategoryTest : VRBaseTestCase
@end

@implementation NSURLCategoryTest {
  NSURL *url;
}

- (void)testIsDirectory {
  url = [[NSURL alloc] initFileURLWithPath:@"/System"];
  assertThat(@(url.isDirectory), isYes);

  url = [[NSURL alloc] initFileURLWithPath:@"/bin/ls"];
  assertThat(@(url.isDirectory), isNo);

  url = [[NSURL alloc] initWithString:@"http://taewon.de"];
  XCTAssertThrows(url.isDirectory, @"%@ cannot have a dir property", url);
}

@end
