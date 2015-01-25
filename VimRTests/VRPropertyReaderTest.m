/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRPropertyReader.h"


static NSNumber *has_modifier(NSEventModifierFlags actual, NSEventModifierFlags expected) {
  return [[NSNumber alloc] initWithBool:((actual & expected) != 0)];
}


@interface VRPropertyReaderTest : VRBaseTestCase
@end


@implementation VRPropertyReaderTest {
  VRPropertyReader *propertyReader;
}

- (void)testSelectNthTabModifiers1 {
  propertyReader = [self propertyReaderWithTestFile:@"test_vimr_rc_1"];

  assertThat(@(propertyReader.useSelectNthTabBindings), isYes);

  NSEventModifierFlags modifierFlags = propertyReader.selectNthTabModifiers;
  assertThat(has_modifier(modifierFlags, NSCommandKeyMask), isYes);
  assertThat(has_modifier(modifierFlags, NSShiftKeyMask), isNo);
  assertThat(has_modifier(modifierFlags, NSAlternateKeyMask), isNo);
  assertThat(has_modifier(modifierFlags, NSControlKeyMask), isNo);
}

- (void)testSelectNthTabModifiers2 {
  propertyReader = [self propertyReaderWithTestFile:@"test_vimr_rc_2"];

  assertThat(@(propertyReader.useSelectNthTabBindings), isNo);

  NSEventModifierFlags modifierFlags = propertyReader.selectNthTabModifiers;
  assertThat(has_modifier(modifierFlags, NSCommandKeyMask), isYes);
  assertThat(has_modifier(modifierFlags, NSShiftKeyMask), isYes);
  assertThat(has_modifier(modifierFlags, NSAlternateKeyMask), isNo);
  assertThat(has_modifier(modifierFlags, NSControlKeyMask), isNo);
}

- (void)testSelectNthTabModifiers3 {
  propertyReader = [self propertyReaderWithTestFile:@"test_vimr_rc_3"];

  assertThat(@(propertyReader.useSelectNthTabBindings), isYes);

  NSEventModifierFlags modifierFlags = propertyReader.selectNthTabModifiers;
  assertThat(has_modifier(modifierFlags, NSCommandKeyMask), isYes);
  assertThat(has_modifier(modifierFlags, NSShiftKeyMask), isYes);
  assertThat(has_modifier(modifierFlags, NSAlternateKeyMask), isYes);
  assertThat(has_modifier(modifierFlags, NSControlKeyMask), isNo);
}

- (void)testSelectNthTabModifiers4 {
  propertyReader = [self propertyReaderWithTestFile:@"test_vimr_rc_4"];

  assertThat(@(propertyReader.useSelectNthTabBindings), isYes);

  NSEventModifierFlags modifierFlags = propertyReader.selectNthTabModifiers;
  assertThat(has_modifier(modifierFlags, NSCommandKeyMask), isNo);
  assertThat(has_modifier(modifierFlags, NSShiftKeyMask), isNo);
  assertThat(has_modifier(modifierFlags, NSAlternateKeyMask), isNo);
  assertThat(has_modifier(modifierFlags, NSControlKeyMask), isYes);
}

- (void)testRandomRead {
  propertyReader = [self propertyReaderWithTestFile:@"test_vimr_rc_1"];

  NSDictionary *properties = propertyReader.globalProperties;

  assertThat(properties.allKeys, hasCountOf(5));
  assertThat(properties[@"a"], is(@"1"));
  assertThat(properties[@"b"], is(@"2"));
  assertThat(properties[@"c"], is(@"3"));
  assertThat(properties[@"d"], is(@""));
  assertThat(properties[@"open.quickly.patterns"], is(@"*/.git/*, .gitignore"));
}

- (VRPropertyReader *)propertyReaderWithTestFile:(NSString *)testFile {
  NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:testFile withExtension:@""];

  VRPropertyReader *reader = [[VRPropertyReader alloc] initWithPropertyFileUrl:url];
  reader.fileManager = [NSFileManager defaultManager];

  return reader;
}

@end
