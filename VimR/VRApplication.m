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


static BOOL is_command_key_only(NSUInteger flags) {
  if (!(flags & NSCommandKeyMask)) {
    return NO;
  }

  if (flags & (NSAlphaShiftKeyMask | NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)) {
    return NO;
  }

  return YES;
}


@implementation VRKeyShortcut

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
  NSMutableArray *_keyShortcuts;
  NSMutableDictionary *_keyEquivalentCache;
  NSSet *_allKeys;
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

#pragma mark Public
- (void)addKeyShortcutItems:(NSArray *)items {
  for (VRKeyShortcut *item in items) {
    [_keyShortcuts addObject:item];
    _keyEquivalentCache[item.keyEquivalent] = item;
  }

  _allKeys = [[NSSet alloc] initWithArray:_keyEquivalentCache.allKeys];
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
  if (![_allKeys containsObject:charactersIgnoringModifiers]) {
    [super sendEvent:theEvent];
    return;
  }

  NSResponder *responder = self.keyWindow;
  do {
    VRKeyShortcut *item = _keyEquivalentCache[charactersIgnoringModifiers];
    SEL aSelector = item.action;
    if ([responder respondsToSelector:aSelector]) {
      DDLogDebug(@"%@ responds to the selector %@. Invoking on the main thread.", responder, NSStringFromSelector(aSelector));
      [responder performSelectorOnMainThread:aSelector withObject:item waitUntilDone:YES];
      return;
    }
  } while (responder = responder.nextResponder);

  [super sendEvent:theEvent];
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
