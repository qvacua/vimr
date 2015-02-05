/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VROpenQuicklyIgnorePattern.h"


@interface VROpenQuicklyIgnorePatternTest : VRBaseTestCase
@end


@implementation VROpenQuicklyIgnorePatternTest {
  VROpenQuicklyIgnorePattern *pattern;
}

- (void)testMatchFolder {
  pattern = [[VROpenQuicklyIgnorePattern alloc] initWithPattern:@"*/.git"];

  assertThat(@([pattern matchesPath:@"/a/b/c/.git"]), isYes);
  assertThat(@([pattern matchesPath:@"/a/b/c/.git/d"]), isYes);
  assertThat(@([pattern matchesPath:@"/a/b/c/.git/d/e"]), isYes);

  assertThat(@([pattern matchesPath:@"/a/b/c/.gitfolder/d"]), isNo);
  assertThat(@([pattern matchesPath:@"/a/b/c/1.git/d"]), isNo);
  assertThat(@([pattern matchesPath:@".git"]), isNo);
  assertThat(@([pattern matchesPath:@"/a/b/c/.hg/d"]), isNo);
}

@end
