/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "NSArray+VR.h"


@interface NSArrayCategoryTest : VRBaseTestCase
@end


@implementation NSArrayCategoryTest

- (void)testIsEmpty {
  assertThat(@(@[].isEmpty), isYes);
  assertThat(@(@[@1].isEmpty), isNo);
}

@end
