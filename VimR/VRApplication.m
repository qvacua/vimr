/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <CocoaLumberjack/DDTTYLogger.h>
#import <MacVimFramework/MacVimFramework.h>
#import "VRApplication.h"
#import "VRUtils.h"
#import "VRDefaultLogSetting.h"
#import "VRLogFormatter.h"
#import "VRMainWindow.h"
#import "VRKeyBinding.h"


static NSString *bit_string(NSUInteger mask) {
  NSMutableString *mutableStringWithBits = [NSMutableString new];
  for (int8_t bitIndex = 0; bitIndex < sizeof(mask) * 8; bitIndex++) {
    [mutableStringWithBits insertString:mask & 1 ? @"1" : @"0" atIndex:0];
    mask >>= 1;
  }
  return [mutableStringWithBits copy];
}

static BOOL is_matching_modifiers(NSEventModifierFlags expectedModifiers, NSUInteger actualModifiers) {
  return (expectedModifiers & actualModifiers) == expectedModifiers;
}


@implementation VRApplication {
  NSMutableArray *_keyShortcuts;
  NSMutableDictionary *_keyEquivalentCache;
  NSSet *_allKeys;
  NSEventModifierFlags _modifiers;
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _keyShortcuts = [[NSMutableArray alloc] initWithCapacity:10];
  _keyEquivalentCache = [[NSMutableDictionary alloc] initWithCapacity:10];

  [self initMacVimFramework];
  [self initLogger];

  [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];

  return self;
}

- (NSString *)bitString:(NSUInteger)mask {
  NSString *str = @"";
  for (NSUInteger i = 0; i < 8; i++) {
    // Prepend "0" or "1", depending on the bit
    str = [NSString stringWithFormat:@"%@%@", mask & 1 ? @"1" : @"0", str];
    mask >>= 1;
  }
  return str;
}

#pragma mark Public
- (void)addKeyShortcutItems:(NSArray *)items {
  for (VRKeyBinding *item in items) {
    [_keyShortcuts addObject:item];
    _keyEquivalentCache[item.keyEquivalent] = item;
  }

  _modifiers = [items[0] modifiers];
  _allKeys = [[NSSet alloc] initWithArray:_keyEquivalentCache.allKeys];
}

#pragma mark NSApplication
- (void)sendEvent:(NSEvent *)theEvent {
  if (self.keyWindow == nil
      || theEvent.type != NSKeyDown
      || !is_matching_modifiers(_modifiers, theEvent.modifierFlags)) {

    [super sendEvent:theEvent];
    return;
  }

  NSString *characters = [self charsStrippingModifiers:theEvent];
  if (![_allKeys containsObject:characters]) {
    [super sendEvent:theEvent];
    return;
  }

  NSResponder *responder = self.keyWindow;
  do {
    VRKeyBinding *item = _keyEquivalentCache[characters];
    SEL aSelector = item.action;
    if ([responder respondsToSelector:aSelector]) {
      DDLogDebug(@"%@ responds to the selector %@. Invoking on the main thread.", responder, NSStringFromSelector(aSelector));
      [responder performSelectorOnMainThread:aSelector withObject:item waitUntilDone:YES];
      return;
    }
  } while (responder = responder.nextResponder);

  [super sendEvent:theEvent];
}

- (NSString *)charsStrippingModifiers:(NSEvent *)theEvent {
  // from http://stackoverflow.com/questions/8263618/convert-virtual-key-code-to-unicode-string
  NSString *characters = theEvent.characters;

  TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
  CFDataRef uchr = (CFDataRef) TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *) CFDataGetBytePtr(uchr);

  if (!keyboardLayout) {
    return _modifiers & NSShiftKeyMask ? characters : theEvent.charactersIgnoringModifiers;
  }

  UInt32 deadKeyState = 0;
  UniCharCount maxStringLength = 255;
  UniCharCount actualStringLength = 0;
  UniChar unicodeString[maxStringLength];

  OSStatus status = UCKeyTranslate(
      keyboardLayout,
      theEvent.keyCode, kUCKeyActionDown, 0,
      LMGetKbdType(), 0,
      &deadKeyState,
      maxStringLength,
      &actualStringLength, unicodeString
  );

  if (actualStringLength == 0 && deadKeyState) {
    status = UCKeyTranslate(
        keyboardLayout,
        kVK_Space, kUCKeyActionDown, 0,
        LMGetKbdType(), 0,
        &deadKeyState,
        maxStringLength,
        &actualStringLength, unicodeString
    );
  }

  if (actualStringLength > 0 && status == noErr) {
    return [NSString stringWithCharacters:unicodeString length:(NSUInteger) actualStringLength];
  }

  return _modifiers & NSShiftKeyMask ? characters : theEvent.charactersIgnoringModifiers;
}

#pragma mark Public
- (NSArray *)orderedMainWindows {
  return [self.orderedWindows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
    return [[obj class] isEqualTo:[VRMainWindow class]];
  }]];
}

#pragma mark Private
- (void)initLogger {
  DDTTYLogger *logger = [DDTTYLogger sharedInstance];
  logger.colorsEnabled = YES;
  logger.logFormatter = [[VRLogFormatter alloc] init];
  [DDLog addLogger:logger];
}

- (void)initMacVimFramework {
  [MMUtils setKeyHandlingUserDefaults];
  [MMUtils setInitialUserDefaults];
}

@end
