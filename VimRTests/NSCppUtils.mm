/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRCppUtils.h"


@interface NSCppUtils : VRBaseTestCase
@end


@implementation NSCppUtils

- (void)testChunkIndexes {
  auto result = chunked_indexes(11, 11);
  assertThat(@(result.size()), is(@1));
  [self assertPair:result[0] first:0 second:10];

  result = chunked_indexes(11, 14);
  assertThat(@(result.size()), is(@1));
  [self assertPair:result[0] first:0 second:10];

  result = chunked_indexes(11, 6);
  assertThat(@(result.size()), is(@2));
  [self assertPair:result[0] first:0 second:5];
  [self assertPair:result[1] first:6 second:10];

  result = chunked_indexes(11, 4);
  assertThat(@(result.size()), is(@3));
  [self assertPair:result[0] first:0 second:3];
  [self assertPair:result[1] first:4 second:7];
  [self assertPair:result[2] first:8 second:10];

  result = chunked_indexes(0, 3);
  assertThat(@(result.size()), is(@0));
}

- (void)assertPair:(std::pair<NSUInteger, NSUInteger> const &)pair first:(NSUInteger)first second:(NSUInteger)second {
  assertThat(@(pair.first), is(@(first)));
  assertThat(@(pair.second), is(@(second)));
}

@end
