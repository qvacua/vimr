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

- (void)testParentName {
  url = [NSURL fileURLWithPath:@"/Users/test"];
  assertThat(url.parentName, is(@"Users"));

  url = [NSURL fileURLWithPath:@"/Users"];
  assertThat(url.parentName, is(@"/"));

  url = [NSURL fileURLWithPath:@"/"];
  XCTAssertThrows(url.parentName, @"%@ cannot have a parent", url);
}

- (void)testIsParentForUrl {
  url = [NSURL fileURLWithPath:@"/Users/test"];
  assertThat(@([url isParentToUrl:[NSURL fileURLWithPath:@"/Users/test/test.txt"]]), isYes);
  assertThat(@([url isParentToUrl:[NSURL fileURLWithPath:@"/Users/no"]]), isNo);
  assertThat(@([url isParentToUrl:[NSURL fileURLWithPath:@"/Tes"]]), isNo);

}

@end
