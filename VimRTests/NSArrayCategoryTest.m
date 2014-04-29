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

- (void)testIndexesForChunkSize {
  NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11];

  assertThat([array indexesForChunkSize:11], is(@[[NSValue valueWithRange:NSMakeRange(0, 10)]]));
  assertThat([array indexesForChunkSize:15], is(@[[NSValue valueWithRange:NSMakeRange(0, 10)]]));

  NSMutableArray *indexes = [[NSMutableArray alloc] init];

  [indexes addObject:[NSValue valueWithRange:NSMakeRange(0, 5)]];
  [indexes addObject:[NSValue valueWithRange:NSMakeRange(6, 10)]];
  assertThat([array indexesForChunkSize:6], is(indexes));

  [indexes removeAllObjects];
  [indexes addObject:[NSValue valueWithRange:NSMakeRange(0, 3)]];
  [indexes addObject:[NSValue valueWithRange:NSMakeRange(4, 7)]];
  [indexes addObject:[NSValue valueWithRange:NSMakeRange(8, 10)]];
  assertThat([array indexesForChunkSize:4], is(indexes));
}

@end
