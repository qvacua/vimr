/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "NSString+VR.h"


@interface NSStringCategoryTest : VRBaseTestCase
@end


@implementation NSStringCategoryTest

- (void)testContains {
  assertThat(@([@"test" hasString:@"es"]), isYes);
  assertThat(@([@"test" hasString:@"ab"]), isNo);
}

@end
