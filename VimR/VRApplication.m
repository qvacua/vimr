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


@implementation VRKeyShortcutItem {

}

- (instancetype)initWithAction:(SEL)anAction keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _action = anAction;
  _keyEquivalent = charCode;
  _tag = 0;

  return self;
}

@end


@implementation VRApplication {
  NSMutableArray *_mutableKeyShortcutItems;
  NSMutableDictionary *_keyEquivalentCache;
}

- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  // necessary MacVimFramework initialization {
  [MMUtils setKeyHandlingUserDefaults];
  [MMUtils setInitialUserDefaults];

  [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];
  // } necessary MacVimFramework initialization

  DDTTYLogger *logger = [DDTTYLogger sharedInstance];
  logger.colorsEnabled = YES;
  logger.logFormatter = [[VRLogFormatter alloc] init];
  [DDLog addLogger:logger];

  return self;
}

- (NSArray *)keyShortcutItems {
  return _mutableKeyShortcutItems;
}

- (void)addKeyShortcutItems:(NSArray *)items {
  _mutableKeyShortcutItems = [[NSMutableArray alloc] initWithCapacity:10];
  _keyEquivalentCache = [[NSMutableDictionary alloc] initWithCapacity:10];

  for (VRKeyShortcutItem *item in items) {
    [_mutableKeyShortcutItems addObject:item];
    _keyEquivalentCache[item.keyEquivalent] = item;
  }
}

- (void)sendEvent:(NSEvent *)theEvent {
  if (theEvent.type == NSKeyDown && theEvent.modifierFlags & NSCommandKeyMask) {
    NSString *charactersIgnoringModifiers = theEvent.charactersIgnoringModifiers;
    if ([_keyEquivalentCache.allKeys containsObject:charactersIgnoringModifiers]) {
      DDLogInfo(@"custom key shortcut called: %@", charactersIgnoringModifiers);

      if (self.keyWindow == nil) {
        DDLogError(@"key window nil");
        return;
      }

      NSResponder *responder = self.keyWindow;
      do {
        VRKeyShortcutItem *item = _keyEquivalentCache[charactersIgnoringModifiers];
        SEL aSelector = [item action];
        if ([responder respondsToSelector:aSelector]) {
          DDLogError(@"found one!");
          [responder performSelectorOnMainThread:aSelector withObject:item waitUntilDone:YES];
          return;
        }
      } while(responder = responder.nextResponder);

      return;
    }
  }

  [super sendEvent:theEvent];
}

@end
