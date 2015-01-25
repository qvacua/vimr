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


NSString *const qOpenQuicklyIgnorePatterns = @"open.quickly.ignore.patterns";
NSString *const qSelectNthTabActive = @"global.keybinding.select-nth-tab.active";
NSString *const qSelectNthTabModifier = @"global.keybinding.select-nth-tab.modifier";


@implementation VRPropertyReader {
  NSURL *_propertyFileUrl;
}

- (instancetype)initWithPropertyFileUrl:(NSURL *)url {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _propertyFileUrl = url.copy;
  _globalProperties = [self readPropertiesFromUrl:url];
  _keysForKeyBindings = @[
      @"file.new",
      @"file.new-tab",
      @"file.open",
      @"file.open-in-tab",
      @"file.open-quickly",
      @"file.close",
      @"file.save",
      @"file.save-as",
      @"file.revert-to-saved",
      @"edit.undo",
      @"edit.redo",
      @"edit.cut",
      @"edit.copy",
      @"edit.paste",
      @"edit.delete",
      @"edit.select-all",
      @"view.focus-file-browser",
      @"view.focus-text-area",
      @"view.show-file-browser",
      @"view.put-file-browser-on-right",
      @"view.show-status-bar",
      @"view.font.show-fonts",
      @"view.font.bigger",
      @"view.font.smaller",
      @"view.enter-full-screen",
      @"navigate.show-folders-first",
      @"navigate.show-hidden-files",
      @"navigate.sync-vim-pwd",
      @"preview.show-preview",
      @"preview.refresh",
      @"window.minimize",
      @"window.zoom",
      @"window.select-next-tab",
      @"window.select-previous-tab",
      @"window.bring-all-to-front",
      @"help.vimr-help",
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
  if (modifierAsStr == nil) {
    return NSCommandKeyMask;
  }

  NSArray *modifierChars = [modifierAsStr componentsSeparatedByString:@"-"];
  return [self modifiersFromProperty:modifierChars];
}

- (VRKeyBinding *)keyBindingForKey:(NSString *)key {
  return nil;
}

- (NSEventModifierFlags)modifiersFromProperty:(NSArray *)chars {
  if (chars.isEmpty) {
    DDLogWarn(@"Something wrong with '%@'", qSelectNthTabModifier);
    return NSCommandKeyMask;
  }

  NSEventModifierFlags result = (NSEventModifierFlags) 0;
  for (NSString *character in chars) {
    if (character.length != 1) {
      DDLogWarn(@"Something wrong with '%@'", qSelectNthTabModifier);
      return NSCommandKeyMask;
    }

    if (![[NSCharacterSet characterSetWithCharactersInString:@"@^~$"] characterIsMember:[character characterAtIndex:0]]) {
      DDLogWarn(@"Something wrong with '%@'", qSelectNthTabModifier);
      return NSCommandKeyMask;
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

- (void)updateKeyBindingsOfMenuItems {
  NSArray *keys = @[
      @"file.new",
      @"file.new-tab",
      @"file.open",
      @"file.open-in-tab",
      @"file.open-quickly",
      @"file.close",
      @"file.save",
      @"file.save-as",
      @"file.revert-to-saved",
      @"edit.undo",
      @"edit.redo",
      @"edit.cut",
      @"edit.copy",
      @"edit.paste",
      @"edit.delete",
      @"edit.select-all",
      @"view.focus-file-browser",
      @"view.focus-text-area",
      @"view.show-file-browser",
      @"view.put-file-browser-on-right",
      @"view.show-status-bar",
      @"view.font.show-fonts",
      @"view.font.bigger",
      @"view.font.smaller",
      @"view.enter-full-screen",
      @"navigate.show-folders-first",
      @"navigate.show-hidden-files",
      @"navigate.sync-vim-pwd",
      @"preview.show-preview",
      @"preview.refresh",
      @"window.minimize",
      @"window.zoom",
      @"window.select-next-tab",
      @"window.select-previous-tab",
      @"window.bring-all-to-front",
      @"help.vimr-help",
  ];

  for (NSString *key in keys) {
    NSString *value = _globalProperties[key];

    if (value == nil) {
      continue;
    }

    if (value.length <= 2) {
      DDLogWarn(@"Something wrong with %@=%@", key, value);
      continue;
    }

    // @-^-~-$-k
    // @-^-~-$-^[
    // @-^-~-$--
    NSArray *components = [value componentsSeparatedByString:@"-"];
    if (components.count <= 2) {
      DDLogWarn(@"Something wrong with %@=%@", key, value);
      continue;
    }

    // @-a
    if (components.count == 2) {

    }

    // @-a
    if (components.count == 2) {

    }
  }
}

@end
