/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRPropertyService.h"
#import "VRKeyBinding.h"
#import "VRMenuItem.h"


static NSNumber *has_modifier(NSEventModifierFlags actual, NSEventModifierFlags expected) {
  return [[NSNumber alloc] initWithBool:((actual & expected) != 0)];
}

@interface VRPropertyServiceTest : VRBaseTestCase
@end


@implementation VRPropertyServiceTest {
  VRPropertyService *propertyReader;
}

- (void)testBindings {
  propertyReader = [self propertyReaderWithTestFile:@"test_binding_vimr_rc"];

  const unichar ch[] = {27};
  NSString *escStr = [NSString stringWithCharacters:ch length:1];

  assertThat(@([escStr characterAtIndex:0]), is(@(27)));

  [self assertBinding:@"file.new" keyEquivalent:@"a" flags:NSCommandKeyMask];
  [self assertBinding:@"file.new-tab" keyEquivalent:@"a" flags:NSControlKeyMask];
  [self assertBinding:@"file.open" keyEquivalent:@"a" flags:NSAlternateKeyMask];
  [self assertBinding:@"file.open-in-tab" keyEquivalent:@"a" flags:NSCommandKeyMask | NSShiftKeyMask];
  [self assertBinding:@"file.open-quickly" keyEquivalent:@"-" flags:NSCommandKeyMask];
  [self assertBinding:@"file.close" keyEquivalent:escStr flags:(NSEventModifierFlags) 0];
  [self assertBinding:@"file.save" keyEquivalent:escStr flags:NSCommandKeyMask];
  [self assertBinding:@"file.save-as" keyEquivalent:@"a" flags:NSCommandKeyMask | NSAlternateKeyMask];
  [self assertBinding:@"file.revert-to-saved" keyEquivalent:@"a" flags:NSCommandKeyMask | NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask];
  [self assertBinding:@"edit.undo" keyEquivalent:@"-" flags:NSCommandKeyMask | NSAlternateKeyMask];
  [self assertBinding:@"edit.redo" keyEquivalent:@"" flags:(NSEventModifierFlags) 0];

  [self assertNilBinding:@"edit.cut"];
  [self assertNilBinding:@"edit.copy"];
  [self assertNilBinding:@"edit.paste"];
  [self assertNilBinding:@"edit.delete"];
  [self assertNilBinding:@"edit.select-all"];
  [self assertNilBinding:@"view.focus-file-browser"];
  [self assertNilBinding:@"view.focus-text-area"];
  [self assertNilBinding:@"view.show-file-browser"];
  [self assertNilBinding:@"view.put-file-browser-on-right"];
  [self assertNilBinding:@"view.show-status-bar"];
  [self assertNilBinding:@"view.font.show-fonts"];
  [self assertNilBinding:@"view.font.bigger"];
  [self assertNilBinding:@"view.font.smaller"];
  [self assertNilBinding:@"view.enter-full-screen"];
  [self assertNilBinding:@"navigate.show-folders-first"];
  [self assertNilBinding:@"navigate.show-hidden-files"];
  [self assertNilBinding:@"navigate.sync-vim-pwd"];
  [self assertNilBinding:@"preview.show-preview"];
  [self assertNilBinding:@"preview.refresh"];
  [self assertNilBinding:@"window.minimize"];
  [self assertNilBinding:@"window.zoom"];
  [self assertNilBinding:@"window.select-next-tab"];
  [self assertNilBinding:@"window.select-previous-tab"];
  [self assertNilBinding:@"window.bring-all-to-front"];
  [self assertNilBinding:@"help.vimr-help"];
}

- (void)assertNilBinding:(NSString *)key {
  VRMenuItem *menuItem = mock([VRMenuItem class]);
  [given([menuItem menuItemIdentifier]) willReturn:key];

  assertThat([propertyReader keyBindingForMenuItem:menuItem], nilValue());
}

- (void)assertBinding:(NSString *)key keyEquivalent:(NSString *)keyEquivalent flags:(NSEventModifierFlags)flags {
  VRMenuItem *menuItem = mock([VRMenuItem class]);
  [given([menuItem menuItemIdentifier]) willReturn:key];
  VRKeyBinding *binding = [propertyReader keyBindingForMenuItem:menuItem];

  assertThat(binding.keyEquivalent, is(keyEquivalent));
  assertThat(@(binding.modifiers), is(@(flags)));
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

- (VRPropertyService *)propertyReaderWithTestFile:(NSString *)testFile {
  NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:testFile withExtension:@""];

  VRPropertyService *reader = [[VRPropertyService alloc] initWithPropertyFileUrl:url];
  reader.fileManager = [NSFileManager defaultManager];

  return reader;
}

@end
