/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimTab.h"
#import "NeoVimWindow.h"


@implementation NeoVimTab

- (instancetype)initWithHandle:(NSInteger)handle windows:(NSArray <NeoVimWindow *> *)windows current:(bool)current {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _handle = handle;
  _windows = windows;
  _isCurrent = current;

  return self;
}

- (NeoVimWindow *)currentWindow {
  for (NeoVimWindow *window in self.windows) if (window.isCurrentInTab) return window;
  return nil;
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.handle=%li", self.handle];
  [description appendFormat:@", self.windows=%@", self.windows];
  [description appendFormat:@", self.current=%d", self.isCurrent];
  [description appendString:@">"];
  return description;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.handle) forKey:@"handle"];
  [coder encodeObject:self.windows forKey:@"windows"];
  [coder encodeBool:self.isCurrent forKey:@"current"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    NSNumber *objHandle = [coder decodeObjectForKey:@"handle"];
    _handle = objHandle.integerValue;
    _windows = [coder decodeObjectForKey:@"windows"];
    _isCurrent = [coder decodeBoolForKey:@"current"];
  }

  return self;
}

@end
