/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRCustomApplication.h"
#import "VRUtils.h"
#import "VRDefaultLogSetting.h"


@implementation VRKeyShortcutItem {

}

- (instancetype)initWithAction:(SEL)anAction keyEquivalent:(NSString *)charCode {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _action = anAction;
  _keyEquivalent = charCode;
  _tag = 0;

  return self;
}

@end


@implementation VRCustomApplication {
  NSMutableArray *_mutableKeyShortcutItems;
  NSMutableDictionary *_keyEquivalentCache;
}

- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  NSLog(@"################## not nil");

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

      [self.keyWindow.firstResponder performSelector:[_keyEquivalentCache[charactersIgnoringModifiers] action]];
      return;
    }
  }

  [super sendEvent:theEvent];
}

@end
