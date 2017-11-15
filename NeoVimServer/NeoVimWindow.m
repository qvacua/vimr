//
// Created by Tae Won Ha on 22/10/16.
// Copyright (c) 2016 Tae Won Ha. All rights reserved.
//

#import "NeoVimWindow.h"
#import "NeoVimBuffer.h"


@implementation NeoVimWindow

- (instancetype)initWithHandle:(NSInteger)handle buffer:(NeoVimBuffer *)buffer currentInTab:(bool)current {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _handle = handle;
  _buffer = buffer;
  _isCurrentInTab = current;

  return self;
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.handle=%li", self.handle];
  [description appendFormat:@", self.buffer=%@", self.buffer];
  [description appendFormat:@", self.currentInTab=%d", self.isCurrentInTab];
  [description appendString:@">"];
  return description;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:@(self.handle) forKey:@"handle"];
  [coder encodeObject:self.buffer forKey:@"buffer"];
  [coder encodeBool:self.isCurrentInTab forKey:@"currentInTab"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    NSNumber *objHandle = [coder decodeObjectForKey:@"handle"];
    _handle = objHandle.integerValue;
    _buffer = [coder decodeObjectForKey:@"buffer"];
    _isCurrentInTab = [coder decodeBoolForKey:@"currentInTab"];
  }

  return self;
}

@end
