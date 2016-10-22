/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimBuffer.h"

@implementation NeoVimBuffer

- (instancetype)initWithHandle:(NSUInteger)handle
                      fileName:(NSString *)fileName
                         dirty:(bool)dirty
                       current:(bool)current {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _handle = handle;
  _fileName = fileName;
  _isDirty = dirty;
  _isCurrent = current;

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    NSNumber *objHandle = [coder decodeObjectForKey:@"handle"];
    _handle = objHandle.unsignedIntegerValue;
    _fileName = [coder decodeObjectForKey:@"fileName"];
    _isDirty = [coder decodeBoolForKey:@"dirty"];
    _isCurrent = [coder decodeBoolForKey:@"current"];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.handle) forKey:@"handle"];
  [coder encodeObject:self.fileName forKey:@"fileName"];
  [coder encodeBool:self.isDirty forKey:@"dirty"];
  [coder encodeBool:self.isCurrent forKey:@"current"];
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.handle=%lu", self.handle];
  [description appendFormat:@", self.fileName=%@", self.fileName];
  [description appendFormat:@", self.dirty=%d", self.isDirty];
  [description appendFormat:@", self.current=%d", self.isCurrent];
  [description appendString:@">"];
  return description;
}

- (bool)isTransient {
  if (self.isDirty) {
    return NO;
  }

  if (self.fileName != nil) {
    return NO;
  }

  return YES;
}

@end
