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

- (void)testMatchSuffix {
  pattern = [[VROpenQuicklyIgnorePattern alloc] initWithPattern:@"*.png"];

  assertThat(@([pattern matchesPath:@"/a/b/c/d.png"]), isYes);
  assertThat(@([pattern matchesPath:@"a.png"]), isYes);

  assertThat(@([pattern matchesPath:@"/a/b/c/d.pnge"]), isNo);
  assertThat(@([pattern matchesPath:@"/a/b/c/d.png/e"]), isNo);
}

- (void)testMatchPrefix {
  pattern = [[VROpenQuicklyIgnorePattern alloc] initWithPattern:@"vr*"];

  assertThat(@([pattern matchesPath:@"/a/b/c/vr.png"]), isYes);
  assertThat(@([pattern matchesPath:@"vr.png"]), isYes);

  assertThat(@([pattern matchesPath:@"/a/b/c/wvr.png"]), isNo);
  assertThat(@([pattern matchesPath:@"/a/b/c/wvr.png/e"]), isNo);
}

- (void)testMatchExact {
  pattern = [[VROpenQuicklyIgnorePattern alloc] initWithPattern:@"some"];

  assertThat(@([pattern matchesPath:@"/a/b/c/some"]), isYes);
  assertThat(@([pattern matchesPath:@"some"]), isYes);

  assertThat(@([pattern matchesPath:@"/a/b/c/some1"]), isNo);
  assertThat(@([pattern matchesPath:@"/a/b/c/1some"]), isNo);
}

@end
