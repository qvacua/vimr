 /**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRUserDefaults.h"


@interface VRUserDefaultsTest : VRBaseTestCase
@end

@implementation VRUserDefaultsTest {
}

- (void)testOpenMode {
  assertThat(@(open_mode_from_modifier(0, VROpenModeInNewTab)), is(@(VROpenModeInNewTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask | NSControlKeyMask, VROpenModeInNewTab)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInNewTab)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInNewTab)), is(@(VROpenModeInHorizontalSplit)));

  assertThat(@(open_mode_from_modifier(0, VROpenModeInCurrentTab)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask | NSControlKeyMask, VROpenModeInCurrentTab)), is(@(VROpenModeInNewTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInCurrentTab)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInCurrentTab)), is(@(VROpenModeInHorizontalSplit)));

  assertThat(@(open_mode_from_modifier(0, VROpenModeInVerticalSplit)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask | NSControlKeyMask, VROpenModeInVerticalSplit)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInVerticalSplit)), is(@(VROpenModeInNewTab)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInVerticalSplit)), is(@(VROpenModeInHorizontalSplit)));

  assertThat(@(open_mode_from_modifier(0, VROpenModeInHorizontalSplit)), is(@(VROpenModeInHorizontalSplit)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask | NSControlKeyMask, VROpenModeInHorizontalSplit)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInHorizontalSplit)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInHorizontalSplit)), is(@(VROpenModeInNewTab)));
}

- (void)testOpenModeTransformer {
  VROpenModeValueTransformer *transformer = [[VROpenModeValueTransformer alloc] init];

  assertThat([transformer transformedValue:qOpenModeInNewTabValue], is(@(VROpenModeInNewTab)));
  assertThat([transformer transformedValue:qOpenModeInCurrentTabValue], is(@(VROpenModeInCurrentTab)));
  assertThat([transformer transformedValue:qOpenModeInVerticalSplitValue], is(@(VROpenModeInVerticalSplit)));
  assertThat([transformer transformedValue:qOpenModeInHorizontalSplitValue], is(@(VROpenModeInHorizontalSplit)));
}

- (void)testOpenModeReverseTransformer {
  VROpenModeValueTransformer *transformer = [[VROpenModeValueTransformer alloc] init];

  assertThat([transformer reverseTransformedValue:@(VROpenModeInNewTab)], is(qOpenModeInNewTabValue));
  assertThat([transformer reverseTransformedValue:@(VROpenModeInCurrentTab)], is(qOpenModeInCurrentTabValue));
  assertThat([transformer reverseTransformedValue:@(VROpenModeInVerticalSplit)], is(qOpenModeInVerticalSplitValue));
  assertThat([transformer reverseTransformedValue:@(VROpenModeInHorizontalSplit)], is(qOpenModeInHorizontalSplitValue));
}

@end
