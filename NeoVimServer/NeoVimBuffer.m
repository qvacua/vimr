/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimBuffer.h"

@implementation NeoVimBuffer

- (instancetype)initWithHandle:(NSInteger)handle
                 unescapedPath:(NSString *_Nullable)unescapedPath
                         dirty:(bool)dirty
                      readOnly:(bool)readOnly
                       current:(bool)current
{
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _handle = handle;
  _url = unescapedPath == nil ? nil : [NSURL fileURLWithPath:unescapedPath];
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
    _url = [coder decodeObjectForKey:@"url"];
    _isDirty = [coder decodeBoolForKey:@"dirty"];
    _isReadOnly = [coder decodeBoolForKey:@"readOnly"];
    _isCurrent = [coder decodeBoolForKey:@"current"];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.handle) forKey:@"handle"];
  [coder encodeObject:self.url forKey:@"url"];
  [coder encodeBool:self.isDirty forKey:@"dirty"];
  [coder encodeBool:self.isReadOnly forKey:@"readOnly"];
  [coder encodeBool:self.isCurrent forKey:@"current"];
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
  if (self.url != buffer.url && ![self.url isEqual:buffer.url])
    return NO;
  return YES;
}

- (NSUInteger)hash {
  NSUInteger hash = (NSUInteger) self.handle;
  hash = hash * 31u + [self.url hash];
  return hash;
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.handle=%li", self.handle];
  [description appendFormat:@", self.url=%@", self.url];
  [description appendFormat:@", self.dirty=%d", self.isDirty];
  [description appendFormat:@", self.readOnly=%d", self.isReadOnly];
  [description appendFormat:@", self.current=%d", self.isCurrent];
  [description appendString:@">"];
  return description;
}

- (NSString *)name {
  if (self.url == nil) {
    return nil;
  }

  return self.url.lastPathComponent;
}

- (bool)isTransient {
  if (self.isDirty) {
    return NO;
  }

  if (self.url != nil) {
    return NO;
  }

  return YES;
}

@end
