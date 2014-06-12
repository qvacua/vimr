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
  assertThat(@(open_mode_from_modifier(NSCommandKeyMask, VROpenModeInNewTab)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInNewTab)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInNewTab)), is(@(VROpenModeInHorizontalSplit)));

  assertThat(@(open_mode_from_modifier(0, VROpenModeInCurrentTab)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSCommandKeyMask, VROpenModeInCurrentTab)), is(@(VROpenModeInNewTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInCurrentTab)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInCurrentTab)), is(@(VROpenModeInHorizontalSplit)));

  assertThat(@(open_mode_from_modifier(0, VROpenModeInVerticalSplit)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSCommandKeyMask, VROpenModeInVerticalSplit)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInVerticalSplit)), is(@(VROpenModeInNewTab)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInVerticalSplit)), is(@(VROpenModeInHorizontalSplit)));

  assertThat(@(open_mode_from_modifier(0, VROpenModeInHorizontalSplit)), is(@(VROpenModeInHorizontalSplit)));
  assertThat(@(open_mode_from_modifier(NSCommandKeyMask, VROpenModeInHorizontalSplit)), is(@(VROpenModeInCurrentTab)));
  assertThat(@(open_mode_from_modifier(NSAlternateKeyMask, VROpenModeInHorizontalSplit)), is(@(VROpenModeInVerticalSplit)));
  assertThat(@(open_mode_from_modifier(NSControlKeyMask, VROpenModeInHorizontalSplit)), is(@(VROpenModeInNewTab)));
}

@end
