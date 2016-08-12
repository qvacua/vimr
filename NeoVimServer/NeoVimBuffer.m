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
  _dirty = dirty;
  _current = current;

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    NSNumber *objHandle = [coder decodeObjectForKey:@"handle"];
    _handle = objHandle.unsignedIntegerValue;
    _fileName = [coder decodeObjectForKey:@"fileName"];
    _dirty = [coder decodeBoolForKey:@"dirty"];
    _current = [coder decodeBoolForKey:@"current"];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.handle) forKey:@"handle"];
  [coder encodeObject:self.fileName forKey:@"fileName"];
  [coder encodeBool:self.dirty forKey:@"dirty"];
  [coder encodeBool:self.current forKey:@"current"];
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.handle=%lu", self.handle];
  [description appendFormat:@", self.fileName=%@", self.fileName];
  [description appendFormat:@", self.dirty=%d", self.dirty];
  [description appendFormat:@", self.current=%d", self.current];
  [description appendString:@">"];
  return description;
}

- (bool)isTransient {
  if (self.dirty) {
    return NO;
  }

  if (self.fileName != nil) {
    return NO;
  }

  return YES;
}

@end
