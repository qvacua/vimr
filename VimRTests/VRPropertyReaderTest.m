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
#import "VRKeyBinding.h"


static NSNumber *has_modifier(NSEventModifierFlags actual, NSEventModifierFlags expected) {
  return [[NSNumber alloc] initWithBool:((actual & expected) != 0)];
}

@interface VRPropertyReaderTest : VRBaseTestCase
@end


@implementation VRPropertyReaderTest {
  VRPropertyReader *propertyReader;
}

- (void)testBindings {
  propertyReader = [self propertyReaderWithTestFile:@"test_binding_vimr_rc"];

  const unichar ch[] = {27};
  NSString *escStr = [NSString stringWithCharacters:ch length:1];

  assertThat(@([escStr characterAtIndex:0]), is(@(27)));

  [self assertBinding:@"global.keybinding.menuitem.file.new" keyEquivalent:@"a" flags:NSCommandKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.new-tab" keyEquivalent:@"a" flags:NSControlKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.open" keyEquivalent:@"a" flags:NSAlternateKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.open-in-tab" keyEquivalent:@"a" flags:NSCommandKeyMask | NSShiftKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.open-quickly" keyEquivalent:@"-" flags:NSCommandKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.close" keyEquivalent:escStr flags:(NSEventModifierFlags) 0];
  [self assertBinding:@"global.keybinding.menuitem.file.save" keyEquivalent:escStr flags:NSCommandKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.save-as" keyEquivalent:@"a" flags:NSCommandKeyMask | NSAlternateKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.file.revert-to-saved" keyEquivalent:@"a" flags:NSCommandKeyMask | NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask];
  [self assertBinding:@"global.keybinding.menuitem.edit.undo" keyEquivalent:@"-" flags:NSCommandKeyMask | NSAlternateKeyMask];

  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.edit.redo"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.edit.cut"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.edit.copy"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.edit.paste"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.edit.delete"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.edit.select-all"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.focus-file-browser"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.focus-text-area"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.show-file-browser"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.put-file-browser-on-right"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.show-status-bar"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.font.show-fonts"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.font.bigger"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.font.smaller"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.view.enter-full-screen"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.navigate.show-folders-first"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.navigate.show-hidden-files"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.navigate.sync-vim-pwd"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.preview.show-preview"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.preview.refresh"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.window.minimize"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.window.zoom"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.window.select-next-tab"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.window.select-previous-tab"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.window.bring-all-to-front"], nilValue());
  assertThat([propertyReader keyBindingForKey:@"global.keybinding.menuitem.help.vimr-help"], nilValue());
}

- (void)assertBinding:(NSString *)key keyEquivalent:(NSString *)keyEquivalent flags:(NSEventModifierFlags)flags {
  VRKeyBinding *binding = [propertyReader keyBindingForKey:key];

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

- (VRPropertyReader *)propertyReaderWithTestFile:(NSString *)testFile {
  NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:testFile withExtension:@""];

  VRPropertyReader *reader = [[VRPropertyReader alloc] initWithPropertyFileUrl:url];
  reader.fileManager = [NSFileManager defaultManager];

  return reader;
}

@end
