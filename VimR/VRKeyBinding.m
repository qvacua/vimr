/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRKeyBinding.h"
#import "VRUtils.h"


@implementation VRKeyBinding

- (instancetype)initWithAction:(SEL)anAction modifiers:(NSEventModifierFlags)modifiers keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

      _action = anAction;
  _keyEquivalent = charCode;
  _tag = tag;
  _modifiers = modifiers;

  return self;
}

@end
