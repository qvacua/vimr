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


static BOOL is_command_key_only(NSEventModifierFlags flags) {
  if (!(flags & NSCommandKeyMask)) {
    return NO;
  }

  if (flags & (NSAlphaShiftKeyMask | NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)) {
    return NO;
  }

  return YES;
}


@implementation VRKeyShortcutItem

- (instancetype)initWithAction:(SEL)anAction keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _action = anAction;
  _keyEquivalent = charCode;
  _tag = tag;

  return self;
}

@end


@implementation VRApplication {
  NSMutableArray *_mutableKeyShortcutItems;
  NSMutableDictionary *_keyEquivalentCache;
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _mutableKeyShortcutItems = [[NSMutableArray alloc] initWithCapacity:10];
  _keyEquivalentCache = [[NSMutableDictionary alloc] initWithCapacity:10];

  // necessary MacVimFramework initialization {
  [MMUtils setKeyHandlingUserDefaults];
  [MMUtils setInitialUserDefaults];

  [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];
  // } necessary MacVimFramework initialization

  [self initLogger];

  return self;
}

#pragma mark Public
- (NSArray *)keyShortcutItems {
  return _mutableKeyShortcutItems;
}

- (void)addKeyShortcutItems:(NSArray *)items {
  for (VRKeyShortcutItem *item in items) {
    [_mutableKeyShortcutItems addObject:item];
    _keyEquivalentCache[item.keyEquivalent] = item;
  }
}

#pragma mark NSApplication
- (void)sendEvent:(NSEvent *)theEvent {
  if (self.keyWindow == nil
      || theEvent.type != NSKeyDown
      || !is_command_key_only(theEvent.modifierFlags)) {
    [super sendEvent:theEvent];
    return;
  }

  NSString *charactersIgnoringModifiers = theEvent.charactersIgnoringModifiers;
  if (![_keyEquivalentCache.allKeys containsObject:charactersIgnoringModifiers]) {
    [super sendEvent:theEvent];
    return;
  }

  NSResponder *responder = self.keyWindow;
  do {
    VRKeyShortcutItem *item = _keyEquivalentCache[charactersIgnoringModifiers];
    SEL aSelector = item.action;
    if ([responder respondsToSelector:aSelector]) {
      DDLogDebug(@"%@ responds to the selector %@. Invoking on the main thread.", responder, NSStringFromSelector(aSelector));
      [responder performSelectorOnMainThread:aSelector withObject:item waitUntilDone:YES];
      return;
    }
  } while (responder = responder.nextResponder);

  [super sendEvent:theEvent];
}

#pragma mark Private
- (void)initLogger {
  DDTTYLogger *logger = [DDTTYLogger sharedInstance];
  logger.colorsEnabled = YES;
  logger.logFormatter = [[VRLogFormatter alloc] init];
  [DDLog addLogger:logger];
}

@end
