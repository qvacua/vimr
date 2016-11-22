/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimBuffer.h"

@implementation NeoVimBuffer

- (instancetype)initWithHandle:(NSInteger)handle
                      fileName:(NSString *)fileName
                         dirty:(bool)dirty
                      readOnly:(bool)readOnly
                       current:(bool)current {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _handle = handle;
  _fileName = fileName;
  _isDirty = dirty;
  _isReadOnly = readOnly;
  _isCurrent = current;

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    NSNumber *objHandle = [coder decodeObjectForKey:@"handle"];
    _handle = objHandle.integerValue;
    _fileName = [coder decodeObjectForKey:@"fileName"];
    _isDirty = [coder decodeBoolForKey:@"dirty"];
    _isReadOnly = [coder decodeBoolForKey:@"readOnly"];
    _isCurrent = [coder decodeBoolForKey:@"current"];
  }

  return self;
}

- (BOOL)isEqual:(id)other {
  if (other == self)
    return YES;
  if (!other || ![[other class] isEqual:[self class]])
    return NO;

  return [self isEqualToBuffer:other];
}

- (BOOL)isEqualToBuffer:(NeoVimBuffer *)buffer {
  if (self == buffer)
    return YES;
  if (buffer == nil)
    return NO;
  if (self.handle != buffer.handle)
    return NO;
  return YES;
}

- (NSUInteger)hash {
  return (NSUInteger) self.handle;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.handle) forKey:@"handle"];
  [coder encodeObject:self.fileName forKey:@"fileName"];
  [coder encodeBool:self.isDirty forKey:@"dirty"];
  [coder encodeBool:self.isReadOnly forKey:@"readOnly"];
  [coder encodeBool:self.isCurrent forKey:@"current"];
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.handle=%li", self.handle];
  [description appendFormat:@", self.fileName=%@", self.fileName];
  [description appendFormat:@", self.dirty=%d", self.isDirty];
  [description appendFormat:@", self.readOnly=%d", self.isReadOnly];
  [description appendFormat:@", self.current=%d", self.isCurrent];
  [description appendString:@">"];
  return description;
}

- (NSString *)name {
  if (self.fileName == nil) {
    return nil;
  }

  return self.fileName.lastPathComponent;
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
