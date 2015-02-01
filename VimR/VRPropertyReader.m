/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPropertyReader.h"
#import "VRDefaultLogSetting.h"
#import "VRKeyBinding.h"
#import "VRUtils.h"
#import "NSArray+VR.h"
#import "VRMenuItem.h"


NSString *const qOpenQuicklyIgnorePatterns = @"open.quickly.ignore.patterns";
NSString *const qSelectNthTabActive = @"global.keybinding.select-nth-tab.active";
NSString *const qSelectNthTabModifier = @"global.keybinding.select-nth-tab.modifier";


static inline NSString *esc_string() {
  const unichar escape[] = {27};
  return [NSString stringWithCharacters:escape length:1];
}


@implementation VRPropertyReader {
  NSURL *_propertyFileUrl;
}

- (instancetype)initWithPropertyFileUrl:(NSURL *)url {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _propertyFileUrl = url.copy;
  _globalProperties = [self readPropertiesFromUrl:url];
  _keysForKeyBindings = @[
      @"global.keybinding.menuitem.file.new",
      @"global.keybinding.menuitem.file.new-tab",
      @"global.keybinding.menuitem.file.open",
      @"global.keybinding.menuitem.file.open-in-tab",
      @"global.keybinding.menuitem.file.open-quickly",
      @"global.keybinding.menuitem.file.close",
      @"global.keybinding.menuitem.file.save",
      @"global.keybinding.menuitem.file.save-as",
      @"global.keybinding.menuitem.file.revert-to-saved",
      @"global.keybinding.menuitem.edit.undo",
      @"global.keybinding.menuitem.edit.redo",
      @"global.keybinding.menuitem.edit.cut",
      @"global.keybinding.menuitem.edit.copy",
      @"global.keybinding.menuitem.edit.paste",
      @"global.keybinding.menuitem.edit.delete",
      @"global.keybinding.menuitem.edit.select-all",
      @"global.keybinding.menuitem.view.focus-file-browser",
      @"global.keybinding.menuitem.view.focus-text-area",
      @"global.keybinding.menuitem.view.show-file-browser",
      @"global.keybinding.menuitem.view.put-file-browser-on-right",
      @"global.keybinding.menuitem.view.show-status-bar",
      @"global.keybinding.menuitem.view.font.show-fonts",
      @"global.keybinding.menuitem.view.font.bigger",
      @"global.keybinding.menuitem.view.font.smaller",
      @"global.keybinding.menuitem.view.enter-full-screen",
      @"global.keybinding.menuitem.navigate.show-folders-first",
      @"global.keybinding.menuitem.navigate.show-hidden-files",
      @"global.keybinding.menuitem.navigate.sync-vim-pwd",
      @"global.keybinding.menuitem.preview.show-preview",
      @"global.keybinding.menuitem.preview.refresh",
      @"global.keybinding.menuitem.window.minimize",
      @"global.keybinding.menuitem.window.zoom",
      @"global.keybinding.menuitem.window.select-next-tab",
      @"global.keybinding.menuitem.window.select-previous-tab",
      @"global.keybinding.menuitem.window.bring-all-to-front",
      @"global.keybinding.menuitem.help.vimr-help",
  ];

  return self;
}

- (BOOL)useSelectNthTabBindings {
  return ![_globalProperties[qSelectNthTabActive] isEqualToString:@"false"];
}

- (NSDictionary *)readPropertiesFromUrl:(NSURL *)url {
  NSError *error;
  NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
  if (error) {
    DDLogWarn(@"There was an error opening %@: %@", url, error);
    return @{};
  }

  return [self readPropertiesFromString:content];
}

- (NSDictionary *)readPropertiesFromString:(NSString *)input {
  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:30];

  NSArray *lines = [input componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  for (NSString *line in lines) {
    if ([line hasPrefix:@"#"]) {
      continue;
    }

    NSRange range = [line rangeOfString:@"="];
    if (range.location == NSNotFound) {
      continue;
    }

    NSUInteger indexOfValue = range.location + 1;
    if (line.length < indexOfValue) {
      continue;
    }

    NSCharacterSet *whiteSpaces = [NSCharacterSet whitespaceCharacterSet];
    NSString *key = [[line substringWithRange:NSMakeRange(0, range.location)] stringByTrimmingCharactersInSet:whiteSpaces];
    result[key] = [[line substringFromIndex:indexOfValue] stringByTrimmingCharactersInSet:whiteSpaces];
  }

  return result;
}

- (NSDictionary *)workspaceProperties {
  return [self readPropertiesFromUrl:_propertyFileUrl];
}

- (NSEventModifierFlags)selectNthTabModifiers {
  NSString *modifierAsStr = _globalProperties[qSelectNthTabModifier];
  if (blank(modifierAsStr)) {
    return NSCommandKeyMask;
  }

  NSArray *modifierChars = [modifierAsStr componentsSeparatedByString:@"-"];
  if (modifierChars.isEmpty) {
    return NSCommandKeyMask;
  }

  NSEventModifierFlags modifierFlags = [self modifiersFromModifierChars:modifierChars];
  if (modifierFlags == 0) {
    return NSCommandKeyMask;
  }

  return modifierFlags;
}

- (VRKeyBinding *)keyBindingForKey:(NSString *)key {
  NSString *value = _globalProperties[key];

  if (blank(value)) {return nil;}

  if (value.length <= 1) {
    DDLogWarn(@"Something wrong with %@=%@", key, value);
    return nil;
  }

  NSArray *components = [value componentsSeparatedByString:@"-"];
  NSUInteger componentCount = components.count;

  if (componentCount == 0) {
    DDLogWarn(@"Something wrong with %@=%@", key, value);
    return nil;
  }

  // binding = ^[
  if (componentCount == 1) {
    if (![components[0] isEqualToString:@"^["]) {
      DDLogWarn(@"Something wrong with %@=%@", key, value);
      return nil;
    }

    VRMenuItem *menuItem = [self menuItemWithIdentifier:key];
    return [[VRKeyBinding alloc] initWithAction:menuItem.action modifiers:(NSEventModifierFlags) 0 keyEquivalent:esc_string() tag:0];
  }

  NSString *keyEquivalent;
  NSArray *modifiers;

  // binding = @-^-~-$-k
  // binding = @-^-~-$-^[
  // binding = @-^-~-$--
  if (componentCount >= 3 && [components.lastObject isEqualToString:@""] && [components[componentCount - 2] isEqualToString:@""]) {
    keyEquivalent = @"-";
    modifiers = [components subarrayWithRange:NSMakeRange(0, componentCount - 2)];
  } else {
    keyEquivalent = components.lastObject;
    modifiers = [components subarrayWithRange:NSMakeRange(0, componentCount - 1)];
  }

  if (keyEquivalent.length != 1 && ![keyEquivalent isEqualToString:@"^["]) {
    DDLogWarn(@"Something wrong with %@=%@", key, value);
    return nil;
  }

  if ([keyEquivalent isEqualToString:@"^["]) {
    keyEquivalent = esc_string();
  }

  NSEventModifierFlags modifierFlags = [self modifiersFromModifierChars:modifiers];
  if (modifierFlags == 0) {
    DDLogWarn(@"Something wrong with %@=%@", key, value);
    return nil;
  }

  VRMenuItem *menuItem = [self menuItemWithIdentifier:key];
  return [[VRKeyBinding alloc] initWithAction:menuItem.action modifiers:modifierFlags keyEquivalent:keyEquivalent tag:0];
}

- (NSEventModifierFlags)modifiersFromModifierChars:(NSArray *)chars {
  NSEventModifierFlags result = (NSEventModifierFlags) 0;
  for (NSString *character in chars) {
    if (character.length != 1) {
      return NSCommandKeyMask;
    }

    if (![[NSCharacterSet characterSetWithCharactersInString:@"@^~$"] characterIsMember:[character characterAtIndex:0]]) {
      return (NSEventModifierFlags) 0;
    }

    if ([character isEqualToString:@"@"]) {
      result = result | NSCommandKeyMask;
    }

    if ([character isEqualToString:@"^"]) {
      result = result | NSControlKeyMask;
    }

    if ([character isEqualToString:@"~"]) {
      result = result | NSAlternateKeyMask;
    }

    if ([character isEqualToString:@"$"]) {
      result = result | NSShiftKeyMask;
    }
  }

  return result;
}

- (VRMenuItem *)menuItemWithIdentifier:(NSString *)identifier {
  for (NSMenuItem *menu in [NSApp mainMenu].itemArray) {
    for (id menuItem in menu.submenu.itemArray) {
      if ([menuItem isKindOfClass:[VRMenuItem class]]) {
        if ([[menuItem menuItemIdentifier] isEqualToString:identifier]) {
          return menuItem;
        }
      }
    }
  }

  return nil;
}

- (void)updateKeyBindingsOfMenuItems {
}

@end
